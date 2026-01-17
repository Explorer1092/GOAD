# Windows Server 2019 vSphere Configuration

# VM Configuration
vm_name              = "WinServer2019x64-vsphere"
guest_os_type        = "windows2019srv_64Guest"
vm_cpu_cores         = 2
vm_memory            = 4096
vm_disk_size         = 40960

# ISO Configuration
# Update the path to match your datastore and ISO location
# Format: "[datastore_name] path/to/iso"
iso_paths = ["[datastore1] ISO/windows_server_2019.iso"]

# Autounattend file
autounattend_file = "./answer_files/2019_vsphere/Autounattend.xml"

# WinRM Configuration
winrm_username = "vagrant"
winrm_password = "vagrant"

# Template Description
template_description = "Windows Server 2019 64-bit - Template built with Packer for GOAD"
