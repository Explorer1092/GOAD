[CmdletBinding()]
param(
  [string]$UnattendFile
)

function Find-UnattendFile {
  param([string]$fileName)

  $relativePaths = @(
    $fileName,
    (Join-Path "sysprep" $fileName)
  )

  foreach ($drive in (Get-PSDrive -PSProvider FileSystem)) {
    foreach ($relativePath in $relativePaths) {
      $candidate = Join-Path $drive.Root $relativePath
      if (Test-Path $candidate) {
        return (Resolve-Path $candidate).Path
      }
    }
  }

  return $null
}

$requested = $UnattendFile
if (-not $requested -and $env:SYSPREP_UNATTEND) {
  $requested = $env:SYSPREP_UNATTEND
}

$unattendPath = $null
if ($requested) {
  if (Test-Path $requested) {
    $unattendPath = (Resolve-Path $requested).Path
  } else {
    $requestedName = [IO.Path]::GetFileName($requested)
    $unattendPath = Find-UnattendFile $requestedName
  }
}

if (-not $unattendPath) {
  foreach ($defaultName in @("cloudbase-init-unattend.xml", "sysprep-unattend.xml")) {
    $unattendPath = Find-UnattendFile $defaultName
    if ($unattendPath) {
      break
    }
  }
}

if (-not $unattendPath) {
  throw "Unattend file not found. Provide -UnattendFile or set SYSPREP_UNATTEND."
}

Write-Output "Run sysprep with unattend $unattendPath"
Start-Process -FilePath "$env:SystemRoot\System32\Sysprep\Sysprep.exe" -ArgumentList "/generalize /oobe /mode:vm /unattend:`"$unattendPath`"" -Wait
