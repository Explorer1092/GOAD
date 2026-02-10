source "proxmox-iso" "windows" {
  additional_iso_files {
    device           = "sata3"
    iso_checksum     = var.proxmox_autounattend_checksum
    iso_storage_pool = var.proxmox_iso_storage
    iso_url          = var.proxmox_autounattend_iso
    unmount          = true
  }
  additional_iso_files {
    device   = "sata4"
    iso_file = "${var.proxmox_iso_storage}:iso/virtio-win.iso"
    unmount  = true
  }
  additional_iso_files {
    device   = "sata5"
    iso_file = "${var.proxmox_iso_storage}:iso/scripts_withcloudinit.iso"
    unmount  = true
  }
  cloud_init              = true
  cloud_init_storage_pool = var.proxmox_iso_storage
  communicator            = "winrm"
  cores                   = var.proxmox_vm_cpu_cores
  disks {
    disk_size    = var.proxmox_vm_disk_size
    format       = var.proxmox_vm_disk_format
    storage_pool = var.proxmox_vm_storage
    type         = "sata"
  }
  insecure_skip_tls_verify = var.proxmox_skip_tls_verify
  iso_file                 = var.proxmox_iso_file
  memory                   = var.proxmox_vm_memory
  network_adapters {
    bridge   = "vmbr3"
    model    = "virtio"
    vlan_tag = "10"
  }
  node                 = var.proxmox_node
  os                   = var.proxmox_os
  password             = var.proxmox_password
  pool                 = var.proxmox_pool
  proxmox_url          = var.proxmox_url
  sockets              = var.proxmox_vm_sockets
  template_description = var.proxmox_template_description
  template_name        = var.proxmox_vm_name
  username             = var.proxmox_username
  vm_name              = var.proxmox_vm_name
  winrm_insecure       = true
  winrm_no_proxy       = true
  winrm_password       = var.winrm_password
  winrm_timeout        = var.proxmox_winrm_timeout
  winrm_use_ssl        = true
  winrm_username       = var.winrm_username
  task_timeout         = "40m"
}
