[CmdletBinding()]
param(
  [switch]$AllowHttpRemoteAny = $true,
  [switch]$EnableHttpsFirewallRule = $true,
  [switch]$SetTrustedHosts = $true,
  [switch]$ForceHttpListenerPort = $true
)

function Set-NetworkCategoryPrivate {
  $set = $false

  if (Get-Command -Name Get-NetConnectionProfile -ErrorAction SilentlyContinue) {
    try {
      Get-NetConnectionProfile -ErrorAction Stop | Set-NetConnectionProfile -NetworkCategory Private -ErrorAction Stop
      $set = $true
    } catch {
      $set = $false
    }
  }

  if (-not $set) {
    try {
      $networkListManager = [Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]"{DCB00C01-570F-4A9B-8D69-199FDBA5723B}"))
      $connections = $networkListManager.GetNetworkConnections()
      $connections | ForEach-Object { $_.GetNetwork().SetCategory(1) }
    } catch {
      # Best-effort: leave network profile unchanged if it cannot be set.
    }
  }
}

Set-NetworkCategoryPrivate

Enable-PSRemoting -Force
winrm quickconfig -q
winrm quickconfig -transport:http
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="800"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/client/auth '@{Basic="true"}'

if ($ForceHttpListenerPort) {
  winrm set winrm/config/listener?Address=*+Transport=HTTP '@{Port="5985"}'
}

netsh advfirewall firewall set rule group="Windows Remote Administration" new enable=yes
if ($AllowHttpRemoteAny) {
  netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new enable=yes action=allow remoteip=any
} else {
  netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new enable=yes action=allow
}

if ($EnableHttpsFirewallRule) {
  netsh advfirewall firewall set rule name="Windows Remote Management (HTTPS-In)" new enable=yes action=allow
}

if ($SetTrustedHosts) {
  Set-WSManInstance -ResourceURI WinRM/Config/Client -ValueSet @{TrustedHosts="*"}
}

Set-Service winrm -StartupType Automatic
Restart-Service winrm
