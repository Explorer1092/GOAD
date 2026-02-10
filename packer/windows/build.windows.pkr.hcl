locals {
  vsphere_sources = var.enable_vsphere ? ["source.vsphere-iso.windows"] : []
  proxmox_sources = var.enable_proxmox ? ["source.proxmox-iso.windows"] : []
}

build {
  sources = concat(local.vsphere_sources, local.proxmox_sources)

  # vSphere: sysprep with shared unattend
  provisioner "powershell" {
    only              = ["vsphere-iso.windows"]
    elevated_password = var.winrm_password
    elevated_user     = var.winrm_username
    environment_vars  = ["SYSPREP_UNATTEND=sysprep-unattend.xml"]
    scripts           = ["${path.root}/scripts/common/run-sysprep.ps1"]
  }

  # vSphere: schedule delayed shutdown via WinRM as fallback
  provisioner "windows-shell" {
    only   = ["vsphere-iso.windows"]
    inline = ["shutdown /a 2>nul & shutdown /s /t 120 /f /d p:4:1 /c \"Packer fallback shutdown\""]
  }

  # Proxmox: Cloudbase Init prep
  provisioner "powershell" {
    only              = ["proxmox-iso.windows"]
    elevated_password = var.winrm_password
    elevated_user     = var.winrm_username
    scripts           = ["${path.root}/scripts/proxmox/sysprep/cloudbase-init.ps1"]
  }

  provisioner "powershell" {
    only              = ["proxmox-iso.windows"]
    elevated_password = var.winrm_password
    elevated_user     = var.winrm_username
    pause_before      = "1m0s"
    scripts           = ["${path.root}/scripts/proxmox/sysprep/cloudbase-init-config.ps1"]
  }

  provisioner "powershell" {
    only              = ["proxmox-iso.windows"]
    elevated_password = var.winrm_password
    elevated_user     = var.winrm_username
    environment_vars  = ["SYSPREP_UNATTEND=cloudbase-init-unattend.xml"]
    scripts           = ["${path.root}/scripts/common/run-sysprep.ps1"]
  }
}
