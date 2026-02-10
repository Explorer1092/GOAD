enable_vsphere = true
enable_proxmox = false

vsphere_vm_name           = "WinServer2016x64-vsphere"
vsphere_guest_os_type     = "windows9Server64Guest"
vsphere_vm_cpu_cores      = 2
vsphere_vm_memory         = 4096
vsphere_vm_disk_size_mb   = 40960
vsphere_iso_paths         = ["[datastore1] ISO/windows_server_2016.iso"]
vsphere_autounattend_file = "./windows/answer_files/vsphere/windows_server_2016/default/zh-CN/Autounattend.xml"
vsphere_template_description = "Windows Server 2016 64-bit - Template built with Packer for GOAD"
