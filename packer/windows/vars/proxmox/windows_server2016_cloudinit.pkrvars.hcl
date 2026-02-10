enable_proxmox = true
enable_vsphere = false

proxmox_vm_name              = "WinServer2016x64-cloudinit-qcow2"
proxmox_template_description = "Windows Server 2016 64-bit - build 14393 - template built with Packer - cloudinit - {{isotime \"2006-01-02 03:04:05\"}}"
proxmox_iso_file             = "local:iso/windows_server_2016_14393.0_eval_x64.iso"
proxmox_autounattend_iso     = "./windows/iso/Autounattend_winserver2016_cloudinit.iso"
proxmox_autounattend_checksum = "sha256:541abf3910291616d26c1f4ede4478df022282987ab0e7aebcd12f17365dfe0e"
proxmox_vm_cpu_cores         = 2
proxmox_vm_memory            = 4096
proxmox_vm_disk_size         = "40G"
proxmox_vm_sockets           = 1
proxmox_os                   = "win10"
proxmox_vm_disk_format       = "qcow2"
