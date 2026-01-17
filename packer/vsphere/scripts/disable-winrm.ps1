# Disable WinRM (used during initial setup before final configuration)

# Block HTTP connections via firewall
netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new enable=yes action=block
netsh advfirewall firewall set rule group="Windows Remote Management" new enable=yes

# Disable PS Remoting if WinRM is running
$winrmService = Get-Service -Name WinRM
if ($winrmService.Status -eq "Running") {
    Disable-PSRemoting -Force
}

# Stop and disable WinRM service
Stop-Service winrm
Set-Service -Name winrm -StartupType Disabled
