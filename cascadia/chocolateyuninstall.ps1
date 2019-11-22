$ErrorActionPreference = "Stop";

$packageArgs = @{
  packageName   = '{{packageName}}'
}

if ((Uninstall-ChocolateyFont "{{filename}}") -eq 1) {
    Write-Error "Error uninstalling {{displayName}} font"
}