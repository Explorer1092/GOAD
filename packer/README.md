# Packer layout

- `packer/windows` is the HCL2 layout that reuses a single build flow across
  vSphere and Proxmox (recommended).
- `packer/sources.vsphere.pkr.hcl` and `packer/sources.proxmox.pkr.hcl` hold
  shared builder definitions for multi-OS reuse.
- `packer/windows/build_proxmox_iso.sh` generates the Proxmox autounattend
  ISOs used by the unified Windows build.
- `packer/base` holds shared scripts and answer files used by some templates.
- `packer/ubuntu` and `packer/kali` are placeholders for future Linux templates.
