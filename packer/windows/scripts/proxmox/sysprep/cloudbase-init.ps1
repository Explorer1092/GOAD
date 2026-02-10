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

# install Cloudbase-Init
$setupDir = "C:\setup"
New-Item -Path $setupDir -ItemType Directory -Force | Out-Null

$sysprepRoot = Get-SysprepRoot
if (-not $sysprepRoot) {
  throw "Cloudbase-Init media not found; set SYSPREP_DRIVE if needed."
}

$installerPath = Join-Path $sysprepRoot "sysprep\CloudbaseInitSetup_Stable_x64.msi"
Write-Output "Copy CloudbaseInitSetup_Stable_x64.msi from $installerPath"
Copy-Item $installerPath (Join-Path $setupDir "CloudbaseInitSetup_Stable_x64.msi") -Force

Write-Output "Start process CloudbaseInitSetup_Stable_x64.msi"
Start-Process -FilePath (Join-Path $setupDir "CloudbaseInitSetup_Stable_x64.msi") -ArgumentList "/qn /l*v $setupDir\cloud-init.log" -Wait
