# Packer vSphere Windows Templates

This directory contains Packer configurations to build Windows VM templates on VMware vSphere (ESXi/vCenter) for the GOAD (Game of Active Directory) lab.

## Supported Connection Modes

Two connection modes are supported:

### 1. vCenter Mode
Connect through a vCenter Server that manages your ESXi hosts.

```hcl
vsphere_server     = "vcenter.example.com"
vsphere_username   = "administrator@vsphere.local"
vsphere_datacenter = "Datacenter"
vsphere_cluster    = "Cluster"
```

### 2. ESXi Direct Mode
Connect directly to a standalone ESXi host (no vCenter required).

```hcl
vsphere_server     = "192.168.1.100"    # ESXi host IP
vsphere_username   = "root"
vsphere_datacenter = ""                  # Leave empty
vsphere_cluster    = ""                  # Leave empty
vsphere_host       = "192.168.1.100"    # Same as vsphere_server
```

## Prerequisites

1. **Packer installed** (version 1.7.0 or later)
   ```bash
   # macOS
   brew install packer

   # Linux
   curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
   sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
   sudo apt-get update && sudo apt-get install packer
   ```

2. **Windows ISO files** uploaded to your vSphere datastore
   - Windows Server 2019 ISO
   - Windows Server 2016 ISO
   - Windows 10 Enterprise ISO

3. **Network access** to vCenter (port 443) or ESXi host (port 443)

4. **ESXi Direct Mode requirements:**
   - ESXi API accessible on port 443
   - Valid ESXi local account (e.g., root)
   - ESXi license that supports API access

## Quick Start

### 1. Configure vSphere Connection

```bash
cd packer/vsphere
cp config.auto.pkrvars.hcl.template config.auto.pkrvars.hcl
```

Edit `config.auto.pkrvars.hcl` with your vSphere settings.

### 2. Update ISO Paths

Edit the appropriate `.pkvars.hcl` file and update the ISO path:

```hcl
# Example for Windows Server 2019
iso_paths = ["[datastore1] ISO/windows_server_2019.iso"]
```

### 3. Build Templates

```bash
# Build Windows Server 2019
./build_vsphere.sh 2019

# Build Windows Server 2016
./build_vsphere.sh 2016

# Build Windows 10
./build_vsphere.sh 10

# Build all templates
./build_vsphere.sh all

# Validate configurations (no build)
./build_vsphere.sh validate
```

## Directory Structure

```
packer/vsphere/
├── packer.json.pkr.hcl                    # Main Packer configuration
├── variables.pkr.hcl                       # Variable declarations
├── config.auto.pkrvars.hcl.template       # Configuration template
├── windows_server2019_vsphere.pkvars.hcl  # Server 2019 variables
├── windows_server2016_vsphere.pkvars.hcl  # Server 2016 variables
├── windows_10_vsphere.pkvars.hcl          # Windows 10 variables
├── build_vsphere.sh                        # Build script
├── README.md                               # This file
├── answer_files/
│   ├── 2019_vsphere/Autounattend.xml
│   ├── 2016_vsphere/Autounattend.xml
│   └── 10_vsphere/Autounattend.xml
└── scripts/
    ├── enable-winrm.ps1
    ├── disable-winrm.ps1
    ├── fixnetwork.ps1
    ├── ConfigureRemotingForAnsible.ps1
    ├── Install-WMF3Hotfix.ps1
    ├── disable-screensaver.ps1
    └── install-vmware-tools.ps1
```

## Configuration Reference

### vSphere Connection Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `vsphere_server` | vCenter or ESXi host address | Yes |
| `vsphere_username` | vSphere username | Yes |
| `vsphere_password` | vSphere password | Yes |
| `vsphere_insecure` | Skip TLS verification | No (default: true) |
| `vsphere_datacenter` | Datacenter name (vCenter mode) | No |
| `vsphere_cluster` | Cluster name (vCenter mode) | No |
| `vsphere_host` | Specific ESXi host (optional) | No |
| `vsphere_datastore` | Datastore name | Yes |
| `vsphere_network` | Network name | No (default: "VM Network") |
| `vsphere_folder` | VM folder (vCenter mode) | No |

### VM Configuration Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `vm_name` | VM and template name | - |
| `guest_os_type` | VMware guest OS type | windows9Server64Guest |
| `vm_cpu_cores` | Number of CPU cores | 2 |
| `vm_memory` | RAM in MB | 4096 |
| `vm_disk_size` | Disk size in MB | 40960 |

## Key Differences from Proxmox

| Aspect | Proxmox | vSphere |
|--------|---------|---------|
| Builder | `proxmox-iso` | `vsphere-iso` |
| Drivers | VirtIO (extra ISO) | VMware built-in |
| Disk Controller | SATA | PVSCSI |
| Network Card | VirtIO | VMXNET3 |
| Script Delivery | ISO (G:\) | Floppy (A:\) |
| Cloud-Init | Required | Not needed |

## Troubleshooting

### Connection Issues

**vCenter Mode:**
- Verify vCenter is accessible on port 443
- Check username format: `administrator@vsphere.local`
- Ensure account has sufficient privileges

**ESXi Direct Mode:**
- Verify ESXi is accessible on port 443
- Use local ESXi account (e.g., `root`)
- Check ESXi license supports API access

### Build Failures

1. **ISO not found:**
   - Verify ISO path format: `[datastore_name] path/to/iso`
   - Check ISO is uploaded to the specified datastore

2. **WinRM timeout:**
   - Increase `winrm_timeout` value
   - Verify network connectivity to the VM
   - Check Windows firewall settings

3. **Template creation failed:**
   - Ensure sufficient datastore space
   - Verify account has template creation permissions

### Logs

Enable verbose logging:
```bash
PACKER_LOG=1 ./build_vsphere.sh 2019
```

## Template Credentials

All templates are created with the following credentials:

- **Username:** vagrant
- **Password:** vagrant

These credentials are used for:
- Windows local administrator
- WinRM authentication
- Ansible provisioning

## Post-Build Steps

After building templates:

1. **Verify in vSphere:**
   - Check template appears in inventory
   - Verify template settings (CPU, RAM, disk)

2. **Test deployment:**
   ```bash
   # Clone from template and test
   govc vm.clone -vm /Datacenter/vm/Templates/WinServer2019x64-vsphere -on=false test-vm
   ```

3. **Configure GOAD:**
   - Update GOAD configuration to use the new templates
   - Ensure template names match GOAD settings

## License

This project is part of GOAD (Game of Active Directory) by Orange Cyberdefense.
