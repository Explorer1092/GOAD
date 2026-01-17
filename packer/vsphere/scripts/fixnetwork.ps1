# Set network connections to Private category to enable PowerShell Remoting
# Reference: http://blogs.msdn.com/b/powershell/archive/2009/04/03/setting-network-location-to-private.aspx

# Network location feature requires Windows Vista or later
if ([Environment]::OSVersion.Version.Major -lt 6) {
    exit 0
}

# Cannot change network location on domain-joined machines
$domainRoles = @(1, 3, 4, 5)
if ($domainRoles -contains (Get-CimInstance Win32_ComputerSystem).DomainRole) {
    exit 0
}

$networkListManager = [Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]"{DCB00C01-570F-4A9B-8D69-199FDBA5723B}"))
$connections = $networkListManager.GetNetworkConnections()

foreach ($connection in $connections) {
    $network = $connection.GetNetwork()
    $currentCategory = $network.GetCategory()
    Write-Output "$($network.GetName()) category: $currentCategory"

    # Set to Private (1) if currently Public (0)
    if ($currentCategory -eq 0) {
        $network.SetCategory(1)
        Write-Output "$($network.GetName()) changed to Private"
    }
}
