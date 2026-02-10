source "vsphere-iso" "windows" {
  # vSphere connection (supports both vCenter and direct ESXi modes)
  vcenter_server      = var.vsphere_server
  username            = var.vsphere_username
  password            = var.vsphere_password
  insecure_connection = var.vsphere_insecure
  datacenter          = var.vsphere_datacenter
  cluster             = var.vsphere_cluster
  host                = var.vsphere_host
  datastore           = var.vsphere_datastore
  folder              = var.vsphere_folder

  # VM configuration
  vm_name         = var.vsphere_vm_name
  guest_os_type   = var.vsphere_guest_os_type
  CPUs            = var.vsphere_vm_cpu_cores
  cpu_cores       = var.vsphere_vm_cpu_cores
  RAM             = var.vsphere_vm_memory
  RAM_reserve_all = false

  # Disk (LSI Logic SAS - Windows native support, no drivers needed)
  disk_controller_type = ["lsilogic-sas"]
  storage {
    disk_size             = var.vsphere_vm_disk_size_mb
    disk_thin_provisioned = true
  }

  # Network (VMXNET3 for best performance)
  network_adapters {
    network      = var.vsphere_network
    network_card = "vmxnet3"
  }

  # ISO and floppy files
  # Windows ISO (primary CD-ROM) + VMware Tools ISO (secondary CD-ROM)
  iso_paths = concat(var.vsphere_iso_paths, [var.vsphere_vmware_tools_iso_path])
  floppy_files = [
    var.vsphere_autounattend_file,
    "${path.root}/windows/scripts/common/enable-winrm.ps1",
    "${path.root}/windows/scripts/common/disable-winrm.ps1",
    "${path.root}/windows/scripts/vsphere/fixnetwork.ps1",
    "${path.root}/windows/scripts/common/ConfigureRemotingForAnsible.ps1",
    "${path.root}/windows/scripts/common/disable-screensaver.ps1",
    "${path.root}/windows/scripts/common/sysprep-unattend.xml",
    "${path.root}/windows/scripts/vsphere/install-vmware-tools.ps1",
    "${path.root}/windows/scripts/vsphere/install-vmtools.cmd"
  ]

  # Boot and shutdown
  boot_order       = "disk,cdrom"
  boot_wait        = var.vsphere_boot_wait
  # Use VMware Tools guest shutdown instead of WinRM shutdown_command
  # This avoids HTTP 502 errors during concurrent builds
  shutdown_timeout = "15m"

  # WinRM communicator
  communicator   = "winrm"
  winrm_username = var.winrm_username
  winrm_password = var.winrm_password
  winrm_timeout  = var.vsphere_winrm_timeout
  winrm_insecure = true
  winrm_use_ssl  = true

  # Template
  convert_to_template  = false # ESXi standalone doesn't support templates (vCenter only)
  notes                = var.vsphere_template_description
  tools_upgrade_policy = true

  # IP wait
  ip_wait_timeout   = "30m"
  ip_settle_timeout = "5s"
}
