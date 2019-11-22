param([string]$OutputPath = '.\packages\')

# Get config values
$config = ConvertFrom-Json -InputObject (Get-Content config.json -Raw)

if (!(Test-Path -Path $OutputPath)) {
	New-Item -ItemType Directory -Path $OutputPath
}

function Stage-FontPackage($FontConfig) {
	# Create working directories
	New-Item -ItemType Directory -Path ('.\' + $FontConfig.packageName)
	New-Item -ItemType Directory -Path ('.\' + $FontConfig.packageName + '\files\')
	New-Item -ItemType Directory -Path ('.\' + $FontConfig.packageName + '\tools\')
		
	Invoke-WebRequest -Uri ($config.cascadiaProjectRoot + '/releases/download/v' + $config.cascadiaVersion + '/' + $FontConfig.filename) `
		-OutFile ('.\' + $FontConfig.packageName + '\files\' + $FontConfig.filename)
	
	$md5hash = Get-FileHash ('.\' + $FontConfig.packageName + '\files\' + $FontConfig.filename) -Algorithm MD5
	$sha1hash = Get-FileHash ('.\' + $FontConfig.packageName + '\files\' + $FontConfig.filename) -Algorithm SHA1
	
	Copy-Item '.\cascadialicense.txt' -Destination ('.\' + $FontConfig.packageName + '\tools\' + $config.licenseFilename)
	
	((Get-Content -Path ('.\default.nuspec') -Raw) `
		-replace '{{cascadiaProjectRoot}}', $config.cascadiaProjectRoot `
		-replace '{{cascadiaVersion}}', $config.cascadiaVersion `
		-replace '{{packageName}}', $FontConfig.packageName `
		-replace '{{displayName}}', $FontConfig.displayName `
		-replace '{{tags}}', $FontConfig.tags `
		-replace '{{description}}', $FontConfig.description `
		-replace '{{releaseNotes}}', $FontConfig.releaseNotes) `
		| Set-Content -Path ('.\' + $FontConfig.packageName + '\' + $FontConfig.packageName + '.nuspec')
	
	((Get-Content -Path ('.\' + $config.installFilename) -Raw) `
		-replace '{{packageName}}', $FontConfig.packageName `
		-replace '{{displayName}}', $FontConfig.displayName `
		-replace '{{filename}}', $FontConfig.filename) `
		| Set-Content -Path ('.\' + $FontConfig.packageName + '\tools\' + $config.installFilename)
	
	((Get-Content -Path ('.\' + $config.uninstallFilename) -Raw) `
		-replace '{{packageName}}', $FontConfig.packageName `
		-replace '{{displayName}}', $FontConfig.displayName `
		-replace '{{filename}}', $FontConfig.filename) `
		| Set-Content -Path ('.\' + $FontConfig.packageName + '\tools\' + $config.uninstallFilename)
	
	((Get-Content -Path ('.\verification.txt') -Raw) `
		-replace '{{cascadiaProjectRoot}}', $config.cascadiaProjectRoot `
		-replace '{{cascadiaVersion}}', $config.cascadiaVersion `
		-replace '{{filename}}', $FontConfig.filename `
		-replace '{{md5hash}}', $md5hash.Hash `
		-replace '{{sha1hash}}', $sha1hash.Hash) `
		| Set-Content -Path ('.\' + $FontConfig.packageName + '\tools\' + $config.verificationFilename)
}



# Cascadia Code
Stage-FontPackage -FontConfig $config.cascadiaCode
choco pack ('.\' + $config.cascadiaCode.packageName + '\' + $config.cascadiaCode.packageName + '.nuspec') --outputdirectory $OutputPath

# Cascadia Mono
Stage-FontPackage -FontConfig $config.cascadiaMono
choco pack ('.\' + $config.cascadiaMono.packageName + '\' + $config.cascadiaMono.packageName + '.nuspec') --outputdirectory $OutputPath

# Cascadia Code PL
Stage-FontPackage -FontConfig $config.cascadiaCodePL
choco pack ('.\' + $config.cascadiaCodePL.packageName + '\' + $config.cascadiaCodePL.packageName + '.nuspec') --outputdirectory $OutputPath

# Cascadia Mono PL
Stage-FontPackage -FontConfig $config.cascadiaMonoPL
choco pack ('.\' + $config.cascadiaMonoPL.packageName + '\' + $config.cascadiaMonoPL.packageName + '.nuspec') --outputdirectory $OutputPath