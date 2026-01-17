# Enable WinRM for Packer/Ansible provisioning

# Set network connections to Private (required for PS Remoting)
$networkListManager = [Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]"{DCB00C01-570F-4A9B-8D69-199FDBA5723B}"))
$connections = $networkListManager.GetNetworkConnections()
$connections | ForEach-Object { $_.GetNetwork().SetCategory(1) }

# Enable PowerShell Remoting
Enable-PSRemoting -Force

# Configure WinRM
winrm quickconfig -q
winrm quickconfig -transport:http
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="800"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/client/auth '@{Basic="true"}'

# Configure firewall rules
netsh advfirewall firewall set rule group="Windows Remote Administration" new enable=yes
netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new enable=yes action=allow
netsh advfirewall firewall set rule name="Windows Remote Management (HTTPS-In)" new enable=yes action=allow

# Trust all hosts for WinRM client
Set-WSManInstance -ResourceURI WinRM/Config/Client -ValueSet @{TrustedHosts="*"}

# Ensure WinRM starts automatically
Set-Service winrm -StartupType Automatic
Restart-Service winrm
