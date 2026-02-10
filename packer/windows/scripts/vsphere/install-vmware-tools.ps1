# Install VMware Tools from mounted ISO (typically D:, E:, or F: drive)
# Always exit 0 to not fail the packer build

Write-Output "Starting VMware Tools installation..."

# Find VMware Tools installer on available drives
$installer = $null
foreach ($drive in @("D:", "E:", "F:", "G:")) {
    $path64 = "$drive\setup64.exe"
    $path32 = "$drive\setup.exe"

    if (Test-Path $path64) {
        $installer = $path64
        break
    }
    if (Test-Path $path32) {
        $installer = $path32
        break
    }
}

if (-not $installer) {
    Write-Output "VMware Tools installer not found. Skipping."
    exit 0
}

Write-Output "Found installer at: $installer"
Write-Output "Installing VMware Tools..."

try {
    $process = Start-Process -FilePath $installer -ArgumentList '/S /v"/qn REBOOT=R"' -Wait -PassThru
    Write-Output "VMware Tools installer finished with exit code: $($process.ExitCode)"
} catch {
    Write-Output "VMware Tools installation encountered an error: $_"
}

Write-Output "VMware Tools installation complete."
exit 0
