param([string]$OutputPath = "$PSScriptRoot\packages\")

# Get config values
$config = ConvertFrom-Json -InputObject (Get-Content "$PSScriptRoot\config.json" -Raw)

if (!(Test-Path -Path $OutputPath)) {
	New-Item -ItemType Directory -Path $OutputPath
}

function Create-FontPackageFolders($FontConfig, [bool]$IncludeFilesPath = $true) {
	# Create working directories
	New-Item -ItemType Directory -Path ("$PSScriptRoot\" + $FontConfig.packageName)
	New-Item -ItemType Directory -Path ("$PSScriptRoot\" + $FontConfig.packageName + "\tools\")
	
	if ($IncludeFilesPath -eq $true) {
		New-Item -ItemType Directory -Path ("$PSScriptRoot\" + $FontConfig.packageName + "\files\")	
	}
}

function Replace-NuspecTokens($FontConfig, $TemplateFilename = "default.nuspec") {
	((Get-Content -Path ("$PSScriptRoot\" + $TemplateFilename) -Raw) `
		-replace "{{cascadiaProjectRoot}}", $config.cascadiaProjectRoot `
		-replace "{{packageName}}", $FontConfig.packageName `
		-replace "{{displayName}}", $FontConfig.displayName `
		-replace "{{tags}}", ($config.tags + " " + $FontConfig.tags) `
		-replace "{{description}}", $FontConfig.description `
		-replace "{{releaseNotes}}", $FontConfig.releaseNotes `
		-replace "{{cascadiaVersion}}", $config.cascadiaVersion) `
		| Set-Content -Path ("$PSScriptRoot\" + $FontConfig.packageName + "\" + $FontConfig.packageName + ".nuspec")
}

function Stage-FontPackage($FontConfig) {
	Create-FontPackageFolders -FontConfig $FontConfig
	Replace-NuspecTokens -FontConfig $FontConfig
		
	Invoke-WebRequest -Uri ($config.cascadiaProjectRoot + "/releases/download/v" + $config.cascadiaVersion + "/" + $FontConfig.filename) `
		-OutFile ("$PSScriptRoot\" + $FontConfig.packageName + "\files\" + $FontConfig.filename)
	
	$md5hash = Get-FileHash ("$PSScriptRoot\" + $FontConfig.packageName + "\files\" + $FontConfig.filename) -Algorithm MD5
	$sha1hash = Get-FileHash ("$PSScriptRoot\" + $FontConfig.packageName + "\files\" + $FontConfig.filename) -Algorithm SHA1
	
	Copy-Item "$PSScriptRoot\cascadialicense.txt" -Destination ("$PSScriptRoot\" + $FontConfig.packageName + "\tools\" + $config.licenseFilename)
	
	((Get-Content -Path ("$PSScriptRoot\" + $config.installFilename) -Raw) `
		-replace "{{packageName}}", $FontConfig.packageName `
		-replace "{{displayName}}", $FontConfig.displayName `
		-replace "{{filename}}", $FontConfig.filename) `
		| Set-Content -Path ("$PSScriptRoot\" + $FontConfig.packageName + "\tools\" + $config.installFilename)
	
	((Get-Content -Path ("$PSScriptRoot\" + $config.uninstallFilename) -Raw) `
		-replace "{{packageName}}", $FontConfig.packageName `
		-replace "{{displayName}}", $FontConfig.displayName `
		-replace "{{filename}}", $FontConfig.filename) `
		| Set-Content -Path ("$PSScriptRoot\" + $FontConfig.packageName + "\tools\" + $config.uninstallFilename)
	
	((Get-Content -Path ("$PSScriptRoot\verification.txt") -Raw) `
		-replace "{{cascadiaProjectRoot}}", $config.cascadiaProjectRoot `
		-replace "{{filename}}", $FontConfig.filename `
		-replace "{{md5hash}}", $md5hash.Hash `
		-replace "{{sha1hash}}", $sha1hash.Hash `
		-replace "{{cascadiaVersion}}", $config.cascadiaVersion) `
		| Set-Content -Path ("$PSScriptRoot\" + $FontConfig.packageName + "\tools\" + $config.verificationFilename)
}

function Stage-FullFontPackage() {
	$FontConfig = $config.cascadiaFonts

	Create-FontPackageFolders -FontConfig $FontConfig -IncludeFilesPath $false
	Replace-NuspecTokens -FontConfig $FontConfig -TemplateFilename "cascadiafonts.nuspec"
	
	Copy-Item "$PSScriptRoot\cascadialicense.txt" -Destination ("$PSScriptRoot\" + $FontConfig.packageName + "\tools\" + $config.licenseFilename)
}



# Cascadia Code
Stage-FontPackage -FontConfig $config.cascadiaCode
choco pack ("$PSScriptRoot\" + $config.cascadiaCode.packageName + "\" + $config.cascadiaCode.packageName + ".nuspec") --outputdirectory $OutputPath

# Cascadia Mono
Stage-FontPackage -FontConfig $config.cascadiaMono
choco pack ("$PSScriptRoot\" + $config.cascadiaMono.packageName + "\" + $config.cascadiaMono.packageName + ".nuspec") --outputdirectory $OutputPath

# Cascadia Code PL
Stage-FontPackage -FontConfig $config.cascadiaCodePL
choco pack ("$PSScriptRoot\" + $config.cascadiaCodePL.packageName + "\" + $config.cascadiaCodePL.packageName + ".nuspec") --outputdirectory $OutputPath

# Cascadia Mono PL
Stage-FontPackage -FontConfig $config.cascadiaMonoPL
choco pack ("$PSScriptRoot\" + $config.cascadiaMonoPL.packageName + "\" + $config.cascadiaMonoPL.packageName + ".nuspec") --outputdirectory $OutputPath



# Cascadia Fonts
Stage-FullFontPackage
choco pack ("$PSScriptRoot\" + $config.cascadiaFonts.packageName + "\" + $config.cascadiaFonts.packageName + ".nuspec") --outputdirectory $OutputPath