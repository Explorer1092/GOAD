# :simple-vmware: Vmware ESXi

!!! success "Thanks!"
    Thanks to [fsacer](https://github.com/fsacer) and  [viris](https://github.com/viris) for the pr [330](https://github.com/Orange-Cyberdefense/GOAD/pull/330) for vmware esxi provider support

<div align="center">
  <img alt="vagrant" width="153" height="150" src="../img/icon_vagrant.png">
  <img alt="icon_vmmare_esxi" width="176"  height="150" src="../img/icon_vmware_esxi.png">
  <img alt="icon_ansible" width="150"  height="150" src="../img/icon_ansible.png">
</div>

## Prerequisites

- Providing
  - [VMWare ESXi](https://www.vmware.com/products/esxi-and-esx.html) - [no longer free](https://kb.vmware.com/s/article/2107518)
  - [Vagrant](https://developer.hashicorp.com/vagrant/docs)
  - Vagrant plugins:
    - vagrant-reload
    - vagrant-vmware-esxi
    - vagrant-env
    - on some distribution also the vagrant plugins :
      - winrm
      - winrm-fs
      - winrm-elevated
  - ovftool (https://developer.broadcom.com/tools/open-virtualization-format-ovf-tool/latest)

- Provisioning with python
  - Python3 (>=3.8)
  - [ansible-core==2.12.6](https://docs.ansible.com/ansible/latest/index.html)
  - pywinrm

- Or provisioning With Docker
  - [Docker](https://www.docker.com/)

## check dependencies

```bash
./goad.sh -p vmware_esxi
GOAD/vmware_esxi/local/192.168.56.X > check
```

![esxi_check.png](./../img/esxi_check.png)

!!! info
    If there is some missing dependencies goes to the [installation](../installation/index.md) chapter and follow the guide according to your os.

!!! note
    check give mandatory dependencies in red and non mandatory in yellow (but you should be compliant with them too depending one your operating system)

## Install

- To install run the goad script and launch install or use the goad script arguments

```bash
./goad.sh -p vmware_esxi
GOAD/vmware_esxi/local/192.168.56.X > set_lab <lab>  # here choose the lab you want (GOAD/GOAD-Light/NHA/SCCM)
GOAD/vmware_esxi/local/192.168.56.X > set_ip_range <ip_range>  # here choose the  ip range you want to use ex: 192.168.56 (only the first three digits)
GOAD/vmware_esxi/local/192.168.56.X > install
```

![esxi_install](./../img/esxi_install.png)

- or all in command line with arguments

```bash
./goad.sh -t install -p vmware_esxi -l <lab> -ip <ip_range_to_use>
```

## Optional: OpenWrt gateway (self-built router)

When enabled, GOAD VMs use a single LAN adapter and route outbound traffic via an OpenWrt VM.

1) Prepare a Vagrant box for ESXi from the OpenWrt image:
   - Image URL: https://downloads.openwrt.org/releases/24.10.5/targets/x86/64/openwrt-24.10.5-x86-64-generic-ext4-combined-efi.img.gz
   - Convert the image to a VMDK/OVF and add it as a Vagrant box (provider: `vmware_esxi`).
   - The OpenWrt guest must have `open-vm-tools` installed so the ESXi provider can detect its IP.
2) Edit `~/.goad/goad.ini`:

```ini
[vmware_esxi]
esxi_use_router = yes
esxi_router_box = openwrt-24.10.5-x86-64-esxi
esxi_router_box_version =
esxi_router_ip_suffix = 1
```

3) Ensure OpenWrt LAN IP is set to `<ip_range>.1` (for example `192.168.56.1`).

Notes:
- The OpenWrt VM will have two NICs: WAN on `esxi_net_nat`, LAN on `esxi_net_domain`.
- All GOAD VMs will have a single NIC on `esxi_net_domain` and their default gateway set to `<ip_range>.1`.

### Optional: Run Vagrant from the PROVISIONING VM (no host routing)

This mode runs Vagrant inside the PROVISIONING VM so WinRM stays inside the
`<ip_range>.0/24` LAN (no host static routes needed). It is recommended when
`esxi_use_router = yes`.

1) Update `~/.goad/goad.ini`:

```ini
[vmware_esxi]
esxi_vagrant_on_jumpbox = yes
```

2) Use the VM provisioner so the PROVISIONING VM is created:

```bash
./goad.sh -p vmware_esxi -m vm
```

3) Install the **Linux** OVF Tool inside the PROVISIONING VM (required by
`vagrant-vmware-esxi`):

```bash
sudo sh /path/to/VMware-ovftool-*.bundle --eulas-agreed --required
```

4) Create OpenWrt DHCP reservations for all GOAD VMs (static IPs) using the
deterministic MACs defined in the ESXi template:

```bash
python3 scripts/esxi_openwrt_dhcp_hosts.py workspace/<instance_id>/provider/Vagrantfile
```

Apply the generated `uci` commands on the OpenWrt VM, then run `install` from
the GOAD console.

Notes for jumpbox mode:
- GOAD runs `scripts/build_openwrt_esxi_box.sh` on the PROVISIONING VM to build
  an OpenWrt box with a first-boot `open-vm-tools` install. This avoids the
  manual install step and prevents Vagrant from timing out.
- The script requires `qemu-utils` and `kpartx` (installed by the jumpbox setup
  script).
