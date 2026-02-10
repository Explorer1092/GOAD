enable_vsphere = true
enable_proxmox = false

vsphere_vm_name           = "Windows10x64-vsphere"
vsphere_guest_os_type     = "windows9_64Guest"
vsphere_vm_cpu_cores      = 2
vsphere_vm_memory         = 4096
vsphere_vm_disk_size_mb   = 40960
vsphere_iso_paths         = ["[datastore1] ISO/windows_10_enterprise.iso"]
vsphere_autounattend_file = "./windows/answer_files/vsphere/windows_10/default/zh-CN/Autounattend.xml"
vsphere_template_description = "Windows 10 Enterprise 64-bit - Template built with Packer for GOAD"
