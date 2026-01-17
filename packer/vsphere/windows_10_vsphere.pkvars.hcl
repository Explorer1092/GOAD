# Windows 10 Enterprise vSphere Configuration

# VM Configuration
vm_name              = "Windows10x64-vsphere"
guest_os_type        = "windows9_64Guest"
vm_cpu_cores         = 2
vm_memory            = 4096
vm_disk_size         = 40960

# ISO Configuration
# Update the path to match your datastore and ISO location
# Format: "[datastore_name] path/to/iso"
iso_paths = ["[datastore1] ISO/windows_10_enterprise.iso"]

# Autounattend file
autounattend_file = "./answer_files/10_vsphere/Autounattend.xml"

# WinRM Configuration
winrm_username = "vagrant"
winrm_password = "vagrant"

# Template Description
template_description = "Windows 10 Enterprise 64-bit - Template built with Packer for GOAD"
