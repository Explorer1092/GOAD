# vSphere Connection Variables
variable "vsphere_server" {
  type        = string
  description = "vCenter Server or ESXi host address"
}

variable "vsphere_username" {
  type        = string
  description = "vSphere username (e.g., administrator@vsphere.local for vCenter, root for ESXi)"
}

variable "vsphere_password" {
  type        = string
  sensitive   = true
  description = "vSphere password"
}

variable "vsphere_insecure" {
  type        = bool
  default     = true
  description = "Skip TLS certificate verification"
}

variable "vsphere_datacenter" {
  type        = string
  default     = ""
  description = "vCenter datacenter name (leave empty for ESXi direct mode)"
}

variable "vsphere_cluster" {
  type        = string
  default     = ""
  description = "vCenter cluster name (leave empty for ESXi direct mode)"
}

variable "vsphere_host" {
  type        = string
  default     = ""
  description = "ESXi host to run the build on (optional, useful in vCenter mode)"
}

variable "vsphere_datastore" {
  type        = string
  description = "Datastore name for VM storage"
}

variable "vsphere_network" {
  type        = string
  default     = "VM Network"
  description = "Network name for the VM"
}

variable "vsphere_folder" {
  type        = string
  default     = ""
  description = "VM folder path (vCenter mode only)"
}

# VM Configuration Variables
variable "vm_name" {
  type        = string
  description = "Name of the VM and template"
}

variable "guest_os_type" {
  type        = string
  default     = "windows9Server64Guest"
  description = "VMware guest OS type identifier"
}

variable "vm_cpu_cores" {
  type        = number
  default     = 2
  description = "Number of CPU cores"
}

variable "vm_memory" {
  type        = number
  default     = 4096
  description = "RAM in MB"
}

variable "vm_disk_size" {
  type        = number
  default     = 40960
  description = "Disk size in MB"
}

# ISO Configuration
variable "iso_paths" {
  type        = list(string)
  description = "List of ISO paths on the datastore (e.g., [\"[datastore1] ISO/windows_server_2019.iso\"])"
}

variable "vmware_tools_iso_path" {
  type        = string
  default     = "[] /vmimages/tools-isoimages/windows.iso"
  description = "Path to VMware Tools ISO on the ESXi host"
}

variable "autounattend_file" {
  type        = string
  description = "Path to the Autounattend.xml file"
}

# WinRM Configuration
variable "winrm_username" {
  type        = string
  default     = "vagrant"
  description = "WinRM username"
}

variable "winrm_password" {
  type        = string
  default     = "vagrant"
  sensitive   = true
  description = "WinRM password"
}

variable "winrm_timeout" {
  type        = string
  default     = "4h"
  description = "WinRM connection timeout"
}

# Boot Configuration
variable "boot_wait" {
  type        = string
  default     = "3s"
  description = "Time to wait before typing boot command"
}

# Template Configuration
variable "template_description" {
  type        = string
  default     = "Windows template built with Packer for GOAD"
  description = "Description for the template"
}
