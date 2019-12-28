$ErrorActionPreference = "Stop";

$packageArgs = @{
  packageName   = '{{packageName}}'
}

Write-Output "Uninstalling {{displayName}} font..."

if ((Uninstall-ChocolateyFont "{{filename}}") -eq 1) {
    Write-Error "Error uninstalling {{displayName}} font"
} else {
    Write-Output "{{displayName}} font uninstalled successfully"
}