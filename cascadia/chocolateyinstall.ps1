$ErrorActionPreference = "Stop";

$packageArgs = @{
  packageName   = '{{packageName}}'
}

$windowsFonts = $env:SystemRoot + '\Fonts'

$font = $windowsFonts + '\{{filename}}'
if (Test-Path $font) { # Check if the file actually exists
    Write-Output "Attempting to uninstall previous version of {{displayName}} font..."
    if ((Uninstall-ChocolateyFont "{{filename}}") -eq 1) {
        Write-Warning "Error uninstalling previous version of {{displayName}} font"
    } else {
        Write-Output "Previous version of {{displayName}} font uninstalled successfully"
    }
}

Write-Output "Installing {{displayName}} font..."
if ((Install-ChocolateyFont "$env:ChocolateyInstall\lib\{{packageName}}\files\{{filename}}") -eq 1) {
    Write-Error "Error installing {{displayName}} font"
} else {
    Write-Output "{{displayName}} font installed successfully"
}
