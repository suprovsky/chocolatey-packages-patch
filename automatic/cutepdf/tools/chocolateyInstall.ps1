﻿$ErrorActionPreference = 'Stop'

$packageArgs = @{
  packageName   = 'cutepdf'
  fileType      = 'exe'
  url           = 'http://www.cutepdf.com/download/CuteWriter.exe'
  silentArgs    = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-' # Inno Setup Package
  validExitCodes= @(0)
  softwareName  = 'cutepdf*'
  checksum      = '67A7AA9A94B8186CE63E1FC581F69FB852B3B21751A9A6801501607651B716953956A6A21360C24131B3087321026F09029ADF6AA8FBF00E55C41458E4D832A4'
  checksumType  = 'SHA512'
}

# Uninstall any previous versions because the installer will fail if a recent older version is installed.
[array]$key = Get-UninstallRegistryKey -SoftwareName $packageArgs['softwareName']
if ($key.Count -eq 1) {
  $key | ForEach-Object { 
	$installSilentArgs = $packageArgs['silentArgs']
	$installFile = $packageArgs['file']
	$packageArgs['silentArgs'] = '/uninstall /s'
    $packageArgs['file'] = "$($_.UninstallString.Split('/') | select -First 1)"
	
    Uninstall-ChocolateyPackage @packageArgs
	
	$packageArgs['silentArgs'] = $installSilentArgs
	$packageArgs['file'] = $installFile
  }
} elseif ($key.Count -eq 0) {
  Write-Host "CutePDF does not have any older versions that need to be uninstalled"
} elseif ($key.Count -gt 1) {
  Write-Warning "$($key.Count) matches found!"
  Write-Warning "To prevent accidental data loss, no programs will be uninstalled."
  Write-Warning "Please alert package maintainer the following keys were matched:"
  $key | ForEach-Object {Write-Warning "- $($_.DisplayName)"}
}

# Make sure Print Spooler service is up and running
try {
  $serviceName = 'Spooler'
  $spoolerService = Get-WmiObject -Class Win32_Service -Property StartMode,State -Filter "Name='$serviceName'"
  if ($spoolerService -eq $null) { throw "Service $serviceName was not found" }
  Write-Host "Print Spooler service state: $($spoolerService.StartMode) / $($spoolerService.State)"
  if ($spoolerService.StartMode -ne 'Auto' -or $spoolerService.State -ne 'Running') {
    Set-Service $serviceName -StartupType Automatic -Status Running
    Write-Host 'Print Spooler service new state: Auto / Running'
  }
} catch {
  Write-Warning "Unexpected error while checking Print Spooler service: $($_.Exception.Message)"
}

Install-ChocolateyPackage @packageArgs
