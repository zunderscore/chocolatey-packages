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

	Copy-Item ($tempDownloadFolder + "\ttf\" + $FontConfig.filename) -Destination ("$PSScriptRoot\" + $FontConfig.packageName + "\files\" + $FontConfig.filename)
	
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
		-replace "{{legacyFilename}}", $FontConfig.legacyFilename `
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


# Download build
$downloadPath = "$env:TEMP\CascadiaCode_" + $config.cascadiaVersion + ".zip"
Invoke-WebRequest -Uri ($config.cascadiaProjectRoot + "/releases/download/v" + $config.cascadiaVersion + "/CascadiaCode-" + $config.cascadiaVersion + ".zip") `
	-OutFile ($downloadPath)

# Create temp extract folder
$tempDownloadFolder = "$env:TEMP\cascadiacode_" + $config.cascadiaVersion
New-Item -ItemType Directory -Path ($tempDownloadFolder)

# Extract files from build
Add-Type -Assembly "System.IO.Compression.FileSystem"
[IO.Compression.ZipFile]::ExtractToDirectory($downloadPath, $tempDownloadFolder)


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


# Cascadia Code Italic
Stage-FontPackage -FontConfig $config.cascadiaCodeItalic
choco pack ("$PSScriptRoot\" + $config.cascadiaCodeItalic.packageName + "\" + $config.cascadiaCodeItalic.packageName + ".nuspec") --outputdirectory $OutputPath

# Cascadia Mono Italic
Stage-FontPackage -FontConfig $config.cascadiaMonoItalic
choco pack ("$PSScriptRoot\" + $config.cascadiaMonoItalic.packageName + "\" + $config.cascadiaMonoItalic.packageName + ".nuspec") --outputdirectory $OutputPath

# Cascadia Code PL Italic
Stage-FontPackage -FontConfig $config.cascadiaCodePLItalic
choco pack ("$PSScriptRoot\" + $config.cascadiaCodePLItalic.packageName + "\" + $config.cascadiaCodePLItalic.packageName + ".nuspec") --outputdirectory $OutputPath

# Cascadia Mono PL Italic
Stage-FontPackage -FontConfig $config.cascadiaMonoPLItalic
choco pack ("$PSScriptRoot\" + $config.cascadiaMonoPLItalic.packageName + "\" + $config.cascadiaMonoPLItalic.packageName + ".nuspec") --outputdirectory $OutputPath



# Cascadia Fonts
Stage-FullFontPackage
choco pack ("$PSScriptRoot\" + $config.cascadiaFonts.packageName + "\" + $config.cascadiaFonts.packageName + ".nuspec") --outputdirectory $OutputPath



# Cleanup
Remove-Item -Path $tempDownloadFolder -Recurse
Remove-Item -Path $downloadPath
