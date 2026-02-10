# Windows templates (multi-provider)

This directory uses Packer HCL2 to share a single build flow across
multiple builders (vSphere and Proxmox). Provider-specific settings live
in var files, while provisioning is centralized in `build.windows.pkr.hcl`.

## Quick start

1) From `packer/windows`, copy the config template:

```
cp config.auto.pkrvars.hcl.template config.auto.pkrvars.hcl
```

2) Edit `config.auto.pkrvars.hcl` with your vSphere or Proxmox connection
   settings.

3) From the repo root `packer/`, initialize plugins:

```
packer init windows
```

4) From the repo root `packer/`, build a template by selecting a provider-specific var file:

```
# vSphere
packer build -var-file=windows/config.auto.pkrvars.hcl \
  -var-file=windows/vars/vsphere/windows_server2019.pkrvars.hcl \
  sources.vsphere.pkr.hcl sources.proxmox.pkr.hcl windows

# Proxmox
packer build -var-file=windows/config.auto.pkrvars.hcl \
  -var-file=windows/vars/proxmox/windows_server2019_cloudinit.pkrvars.hcl \
  sources.vsphere.pkr.hcl sources.proxmox.pkr.hcl windows
```

## Notes

- Provider selection is controlled by `enable_vsphere` and `enable_proxmox`
  inside the var files under `vars/`.
- Shared source blocks live in `packer/sources.vsphere.pkr.hcl` and
  `packer/sources.proxmox.pkr.hcl`.
- Shared scripts live in `packer/windows/scripts` with provider-specific
  subfolders (`vsphere`, `proxmox`) and a `common` pool.
- Shared answer files live in
  `packer/windows/answer_files/<provider>/<os>/<variant>/<locale>/Autounattend.xml`.
- Answer files are generated from templates in `packer/windows/answer_files/templates`
  using `packer/windows/answer_files/render_answer_files.py` and
  `packer/windows/answer_files/variants.json`.
- Proxmox builds require `packer/windows/build_proxmox_iso.sh` to generate
  autounattend ISOs in `packer/windows/iso` and update the checksums in
  `packer/windows/vars/proxmox`.
- Upload `packer/windows/iso/scripts_withcloudinit.iso` to your Proxmox ISO
  storage before building.
