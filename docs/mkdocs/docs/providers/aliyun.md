# :simple-alibabacloud: Aliyun

<div align="center">
  <img alt="terraform" width="167" height="150" src="./../img/icon_terraform.png">
  <img alt="icon_ansible" width="150"  height="150" src="./../img/icon_ansible.png">
</div>

Aliyun provider deploys GOAD on dedicated VPC/vSwitch with a NAT gateway for outbound traffic. A jumpbox is created for remote provisioning.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html)
- Aliyun access keys exported as environment variables:
  - `ALICLOUD_ACCESS_KEY` / `ALICLOUD_SECRET_KEY`
  - or `ALICLOUD_ACCESS_KEY_ID` / `ALICLOUD_ACCESS_KEY_SECRET`

## Goad configuration

```
# ~/.goad/goad.ini
[aliyun]
aliyun_region = ap-southeast-1
aliyun_zone = ap-southeast-1a
aliyun_vpc_cidr = 10.0.0.0/16
aliyun_vswitch_cidr = 10.0.1.0/24
aliyun_nat_gateway_enabled = true
aliyun_tag_prefix = GOAD
aliyun_image_use_custom_first = true
aliyun_windows_custom_image_id = ""
aliyun_windows_public_image_id = ""
aliyun_linux_custom_image_id = ""
aliyun_linux_public_image_id = ""
aliyun_image_owner = "system"
aliyun_windows_image_name_regex = "Windows Server 2019"
aliyun_linux_image_name_regex = "ubuntu_22_04"
```

## Image strategy

- Use Packer-built images first; fall back to public image IDs when custom IDs are empty.
- If image IDs are empty, Terraform selects the most recent public image matching the regex.
- Per-VM overrides (image IDs or `image_name_regex`) can be set in `ad/<lab>/providers/aliyun/windows.tf` and `ad/<lab>/providers/aliyun/linux.tf`.

## Jumpbox access

- Jumpbox uses an EIP and only allows SSH from `jumpbox_whitelist_cidrs` (default is `0.0.0.0/0`).
- Update `jumpbox_whitelist_cidrs` in `template/provider/aliyun/variables.tf` before deploying to restrict access.

## Installation

```bash
./goad.sh -t check -l GOAD -p aliyun
python3 goad.py -t install -l GOAD -p aliyun
```

See `specs/001-aliyun-provider/quickstart.md` for the full step-by-step checklist.

Or from the interactive console:

```bash
GOAD/aliyun/remote/192.168.56.X > install
```

## How it works

- Creates a workspace instance folder with Terraform and inventory files.
- Terraform provisions VPC/vSwitch, security groups, ECS instances, and NAT.
- Jumpbox is prepared and used to run Ansible remotely.
- All resources are tagged with `<lab_name>-<lab_instance_id>`.
