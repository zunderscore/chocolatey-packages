$ErrorActionPreference = "Stop";

$packageArgs = @{
  packageName   = '{{packageName}}'
}

if ((Install-ChocolateyFont "$env:ChocolateyInstall\lib\{{packageName}}\files\{{filename}}") -eq 1) {
    Write-Error "Error installing {{displayName}} font"
}