function Get-SysprepRoot {
  $searchFile = "sysprep\CloudbaseInitSetup_Stable_x64.msi"

  if ($env:SYSPREP_DRIVE) {
    $driveRoot = $env:SYSPREP_DRIVE.TrimEnd("\") + "\"
    if (Test-Path (Join-Path $driveRoot $searchFile)) {
      return $driveRoot
    }
  }

  foreach ($drive in (Get-PSDrive -PSProvider FileSystem)) {
    $candidate = Join-Path $drive.Root $searchFile
    if (Test-Path $candidate) {
      return $drive.Root
    }
  }

  return $null
}

$logPath = "C:\setup\cloud-init.log"
$timeoutSeconds = 1800
$startTime = Get-Date

while ($true) {
  if (Test-Path $logPath) {
    if (Select-String -Path $logPath -Pattern "Installation completed successfully" -Quiet) {
      break
    }
  }

  if ((Get-Date) - $startTime -gt (New-TimeSpan -Seconds $timeoutSeconds)) {
    throw "Timed out waiting for Cloudbase-Init installation to complete."
  }

  Write-Output "Wait cloud-init installation end..."
  Start-Sleep 5
}

echo "Show cloudinit service"
Get-Service -Name cloudbase-init

$sysprepRoot = Get-SysprepRoot
if (-not $sysprepRoot) {
  throw "Cloudbase-Init media not found; set SYSPREP_DRIVE if needed."
}

Write-Output "Move config files to location"
# Move conf files to Cloudbase directory
$confDir = "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf"
Copy-Item (Join-Path $sysprepRoot "sysprep\cloudbase-init.conf") "$confDir\cloudbase-init.conf" -Force
Copy-Item (Join-Path $sysprepRoot "sysprep\cloudbase-init-unattend.conf") "$confDir\cloudbase-init-unattend.conf" -Force
Copy-Item (Join-Path $sysprepRoot "sysprep\cloudbase-init-unattend.xml") "$confDir\cloudbase-init-unattend.xml" -Force

echo "Disable cloudbaseinit at start"
# disable cloudbase-init start
Set-Service -Name cloudbase-init -StartupType Disabled
