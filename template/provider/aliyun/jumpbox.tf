resource "tls_private_key" "jumpbox" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "alicloud_key_pair" "jumpbox" {
  key_pair_name = "${local.lab_identifier}-jumpbox-key"
  public_key    = tls_private_key.jumpbox.public_key_openssh
  tags          = local.tags
}

resource "alicloud_security_group" "jumpbox" {
  count       = var.jumpbox_enabled ? 1 : 0
  name        = "${local.lab_identifier}-jumpbox-sg"
  description = "GOAD jumpbox security group"
  vpc_id      = alicloud_vpc.goad.id
  tags        = local.tags
}

resource "alicloud_security_group_rule" "jumpbox_ssh" {
  for_each = var.jumpbox_enabled ? var.jumpbox_whitelist_cidrs : toset([])

  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "22/22"
  nic_type          = "intranet"
  policy            = "accept"
  priority          = 1
  security_group_id = alicloud_security_group.jumpbox[0].id
  cidr_ip           = each.value
  description       = "Allow SSH to jumpbox"
}

locals {
  jumpbox_image_id = (
    var.image_use_custom_first && length(var.linux_custom_image_id) > 0 ? var.linux_custom_image_id :
    (!var.image_use_custom_first && length(var.linux_public_image_id) > 0 ? var.linux_public_image_id :
    (length(var.linux_public_image_id) > 0 ? var.linux_public_image_id : var.linux_custom_image_id))
  )
}

data "alicloud_images" "jumpbox" {
  count        = length(local.jumpbox_image_id) == 0 ? 1 : 0
  owners       = length(var.linux_image_owner) > 0 ? var.linux_image_owner : var.image_owner
  os_type      = "linux"
  name_regex   = var.linux_image_name_regex
  most_recent  = true
  architecture = "x86_64"
}

resource "alicloud_instance" "jumpbox" {
  count = var.jumpbox_enabled ? 1 : 0

  availability_zone       = var.zone
  vswitch_id              = local.primary_vswitch_id
  security_groups         = [alicloud_security_group.jumpbox[0].id]
  private_ip              = var.jumpbox_private_ip
  instance_type           = var.jumpbox_instance_type
  image_id                = length(local.jumpbox_image_id) > 0 ? local.jumpbox_image_id : data.alicloud_images.jumpbox[0].images[0].id
  key_name                = alicloud_key_pair.jumpbox.key_pair_name
  internet_max_bandwidth_out = 0
  system_disk_category    = "cloud_efficiency"
  system_disk_size        = var.jumpbox_disk_size
  instance_name           = "${local.lab_identifier}-jumpbox"
  host_name               = "jumpbox"
  user_data               = base64encode(templatefile("${path.module}/jumpbox-init.sh.tpl", {
    username = var.jumpbox_username
  }))
  tags = merge(local.tags, {
    Name = "${local.lab_identifier}-jumpbox"
    Role = "jumpbox"
  })

  provisioner "local-exec" {
    command = "echo '${tls_private_key.jumpbox.private_key_pem}' > ../ssh_keys/ubuntu-jumpbox.pem && chmod 600 ../ssh_keys/ubuntu-jumpbox.pem"
  }
}

resource "alicloud_eip_address" "jumpbox" {
  count                = var.jumpbox_enabled ? 1 : 0
  address_name         = "${local.lab_identifier}-jumpbox-eip"
  internet_charge_type = "PayByTraffic"
  bandwidth            = 5
  tags                 = local.tags
}

resource "alicloud_eip_association" "jumpbox" {
  count         = var.jumpbox_enabled ? 1 : 0
  allocation_id = alicloud_eip_address.jumpbox[0].id
  instance_id   = alicloud_instance.jumpbox[0].id
}
