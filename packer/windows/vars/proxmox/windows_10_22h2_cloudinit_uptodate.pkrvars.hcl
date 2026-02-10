enable_proxmox = true
enable_vsphere = false

proxmox_vm_name              = "Windows10x64-22h2-cloudinit-qcow2-uptodate"
proxmox_template_description = "Windows 10 - 22h2 - 64-bit - template built with Packer - {{isotime \"2006-01-02 03:04:05\"}}"
proxmox_iso_file             = "local:iso/Windows-10-22h2_x64_en-us.iso"
proxmox_autounattend_iso     = "./windows/iso/Autounattend_windows10_cloudinit_uptodate.iso"
proxmox_autounattend_checksum = "sha256:bb5a28744077fd0121a04d5955f0b2f7a25d8aa13a1548a7223a4c2e2f1aed61"
proxmox_vm_cpu_cores         = 2
proxmox_vm_memory            = 4096
proxmox_vm_disk_size         = "80G"
proxmox_vm_sockets           = 1
proxmox_os                   = "win10"
proxmox_vm_disk_format       = "qcow2"
