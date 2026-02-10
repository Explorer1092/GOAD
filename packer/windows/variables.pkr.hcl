variable "enable_vsphere" {
  type    = bool
  default = false
}

variable "enable_proxmox" {
  type    = bool
  default = false
}

variable "winrm_username" {
  type    = string
  default = "vagrant"
}

variable "winrm_password" {
  type      = string
  default   = "vagrant"
  sensitive = true
}

# vSphere connection
variable "vsphere_server" {
  type    = string
  default = ""
}

variable "vsphere_username" {
  type    = string
  default = ""
}

variable "vsphere_password" {
  type      = string
  default   = ""
  sensitive = true
}

variable "vsphere_insecure" {
  type    = bool
  default = true
}

variable "vsphere_datacenter" {
  type    = string
  default = ""
}

variable "vsphere_cluster" {
  type    = string
  default = ""
}

variable "vsphere_host" {
  type    = string
  default = ""
}

variable "vsphere_datastore" {
  type    = string
  default = ""
}

variable "vsphere_network" {
  type    = string
  default = ""
}

variable "vsphere_folder" {
  type    = string
  default = ""
}

# vSphere VM
variable "vsphere_vm_name" {
  type    = string
  default = ""
}

variable "vsphere_guest_os_type" {
  type    = string
  default = ""
}

variable "vsphere_vm_cpu_cores" {
  type    = number
  default = 0
}

variable "vsphere_vm_memory" {
  type    = number
  default = 0
}

variable "vsphere_vm_disk_size_mb" {
  type    = number
  default = 0
}

variable "vsphere_iso_paths" {
  type    = list(string)
  default = []
}

variable "vsphere_vmware_tools_iso_path" {
  type    = string
  default = "[] /vmimages/tools-isoimages/windows.iso"
}

variable "vsphere_autounattend_file" {
  type    = string
  default = ""
}

variable "vsphere_winrm_timeout" {
  type    = string
  default = "4h"
}

variable "vsphere_boot_wait" {
  type    = string
  default = "3s"
}

variable "vsphere_template_description" {
  type    = string
  default = ""
}

# Proxmox connection
variable "proxmox_url" {
  type    = string
  default = ""
}

variable "proxmox_username" {
  type    = string
  default = ""
}

variable "proxmox_password" {
  type      = string
  default   = ""
  sensitive = true
}

variable "proxmox_skip_tls_verify" {
  type    = bool
  default = true
}

variable "proxmox_node" {
  type    = string
  default = ""
}

variable "proxmox_pool" {
  type    = string
  default = ""
}

variable "proxmox_vm_storage" {
  type    = string
  default = ""
}

variable "proxmox_iso_storage" {
  type    = string
  default = "local"
}

# Proxmox VM
variable "proxmox_vm_name" {
  type    = string
  default = ""
}

variable "proxmox_template_description" {
  type    = string
  default = ""
}

variable "proxmox_iso_file" {
  type    = string
  default = ""
}

variable "proxmox_autounattend_iso" {
  type    = string
  default = ""
}

variable "proxmox_autounattend_checksum" {
  type    = string
  default = ""
}

variable "proxmox_vm_cpu_cores" {
  type    = number
  default = 0
}

variable "proxmox_vm_memory" {
  type    = number
  default = 0
}

variable "proxmox_vm_disk_size" {
  type    = string
  default = ""
}

variable "proxmox_vm_disk_format" {
  type    = string
  default = ""
}

variable "proxmox_vm_sockets" {
  type    = number
  default = 0
}

variable "proxmox_os" {
  type    = string
  default = ""
}

variable "proxmox_winrm_timeout" {
  type    = string
  default = "120m"
}
