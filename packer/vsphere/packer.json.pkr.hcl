packer {
  required_plugins {
    vsphere = {
      version = ">= 1.2.0"
      source  = "github.com/hashicorp/vsphere"
    }
  }
}

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
  vm_name         = var.vm_name
  guest_os_type   = var.guest_os_type
  CPUs            = var.vm_cpu_cores
  cpu_cores       = var.vm_cpu_cores
  RAM             = var.vm_memory
  RAM_reserve_all = false

  # Disk (LSI Logic SAS - Windows native support, no drivers needed)
  disk_controller_type = ["lsilogic-sas"]
  storage {
    disk_size             = var.vm_disk_size
    disk_thin_provisioned = true
  }

  # Network (VMXNET3 for best performance)
  network_adapters {
    network      = var.vsphere_network
    network_card = "vmxnet3"
  }

  # ISO and floppy files
  # Windows ISO (primary CD-ROM) + VMware Tools ISO (secondary CD-ROM)
  iso_paths = concat(var.iso_paths, [var.vmware_tools_iso_path])
  floppy_files = [
    var.autounattend_file,
    "${path.root}/scripts/enable-winrm.ps1",
    "${path.root}/scripts/disable-winrm.ps1",
    "${path.root}/scripts/fixnetwork.ps1",
    "${path.root}/scripts/ConfigureRemotingForAnsible.ps1",
    "${path.root}/scripts/disable-screensaver.ps1",
    "${path.root}/scripts/install-vmware-tools.ps1",
    "${path.root}/scripts/install-vmtools.cmd"
  ]

  # Boot and shutdown
  boot_order       = "disk,cdrom"
  boot_wait        = var.boot_wait
  # Use VMware Tools guest shutdown instead of WinRM shutdown_command
  # This avoids HTTP 502 errors during concurrent builds
  shutdown_timeout = "15m"

  # WinRM communicator
  communicator   = "winrm"
  winrm_username = var.winrm_username
  winrm_password = var.winrm_password
  winrm_timeout  = var.winrm_timeout
  winrm_insecure = true
  winrm_use_ssl  = true

  # Template
  convert_to_template  = false  # ESXi standalone doesn't support templates (vCenter only)
  notes                = var.template_description
  tools_upgrade_policy = true

  # IP wait
  ip_wait_timeout   = "30m"
  ip_settle_timeout = "5s"
}

build {
  sources = ["source.vsphere-iso.windows"]

  # VMware Tools is already installed via Autounattend.xml FirstLogonCommands

  # Schedule delayed shutdown via WinRM as fallback
  # Then Packer uses VMware Tools for immediate shutdown (no shutdown_command specified)
  # If VMware Tools fails, Windows will shutdown after 120 seconds
  # Note: /a cancels any pending shutdown (from Autounattend.xml reboot)
  provisioner "windows-shell" {
    inline = ["shutdown /a 2>nul & shutdown /s /t 120 /f /d p:4:1 /c \"Packer fallback shutdown\""]
  }
}
