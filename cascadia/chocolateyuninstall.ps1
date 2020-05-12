$ErrorActionPreference = "Stop";

$packageArgs = @{
  packageName   = '{{packageName}}'
}

if ("{{legacyFilename}}" -ne "{{filename}}") {
    Write-Output "Uninstalling legacy {{displayName}} font..."
    
    if ((Uninstall-ChocolateyFont "{{legacyFilename}}") -eq 1) {
        Write-Error "Error uninstalling legacy {{displayName}} font"
    } else {
        Write-Output "Legacy {{displayName}} font uninstalled successfully"
    }
}

Write-Output "Uninstalling {{displayName}} font..."

if ((Uninstall-ChocolateyFont "{{filename}}") -eq 1) {
    Write-Error "Error uninstalling {{displayName}} font"
} else {
    Write-Output "{{displayName}} font uninstalled successfully"
}