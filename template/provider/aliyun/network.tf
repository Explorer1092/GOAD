resource "alicloud_vpc" "goad" {
  name       = "${local.lab_identifier}-vpc"
  cidr_block = var.vpc_cidr
  tags       = local.tags
}

resource "alicloud_vswitch" "goad" {
  for_each          = { for idx, cidr in var.vswitch_cidrs : tostring(idx) => cidr }
  vpc_id            = alicloud_vpc.goad.id
  zone_id           = var.zone
  cidr_block        = each.value
  ipv6_cidr_block   = null
  description       = "GOAD vswitch ${each.key}"
  vswitch_name      = "${local.lab_identifier}-vsw-${each.key}"
  tags              = local.tags
}

locals {
  primary_vswitch_id = values(alicloud_vswitch.goad)[0].id
}

resource "alicloud_nat_gateway" "goad" {
  count         = var.nat_gateway_enabled ? 1 : 0
  vpc_id        = alicloud_vpc.goad.id
  vswitch_id    = local.primary_vswitch_id
  nat_type      = "Enhanced"
  payment_type  = "PayAsYouGo"
  name          = "${local.lab_identifier}-nat"
  internet_charge_type = "PayByLcu"
  tags          = local.tags
}

resource "alicloud_eip_address" "nat" {
  count                 = var.nat_gateway_enabled ? 1 : 0
  bandwidth             = 5
  internet_charge_type  = "PayByTraffic"
  address_name          = "${local.lab_identifier}-nat-eip"
  tags                  = local.tags
}

resource "alicloud_eip_association" "nat" {
  count         = var.nat_gateway_enabled ? 1 : 0
  allocation_id = alicloud_eip_address.nat[0].id
  instance_id   = alicloud_nat_gateway.goad[0].id
}

resource "alicloud_snat_entry" "goad" {
  for_each = var.nat_gateway_enabled ? { for k, v in alicloud_vswitch.goad : k => v.id } : {}

  snat_table_id     = alicloud_nat_gateway.goad[0].snat_table_ids
  source_vswitch_id = each.value
  snat_ip           = alicloud_eip_address.nat[0].ip_address
}
