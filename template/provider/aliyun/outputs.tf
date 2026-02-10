output "lab_identifier" {
  value = local.lab_identifier
}

output "region" {
  value = var.region
}

output "zone" {
  value = var.zone
}

output "vpc_cidr" {
  value = var.vpc_cidr
}

output "vswitch_cidrs" {
  value = var.vswitch_cidrs
}

output "nat_gateway_enabled" {
  value = var.nat_gateway_enabled
}

output "tags" {
  value = local.tags
}

output "vpc_id" {
  value = alicloud_vpc.goad.id
}

output "vswitch_ids" {
  value = { for k, v in alicloud_vswitch.goad : k => v.id }
}

output "security_group_id" {
  value = alicloud_security_group.goad.id
}

output "nat_eip" {
  value = try(alicloud_eip_address.nat[0].ip_address, null)
}

output "windows_private_ips" {
  value = { for k, v in alicloud_instance.windows : k => v.private_ip }
}

output "linux_private_ips" {
  value = try({ for k, v in alicloud_instance.linux : k => v.private_ip }, {})
}

output "jumpbox_public_ip" {
  value = try(alicloud_eip_address.jumpbox[0].ip_address, null)
}

output "jumpbox_private_ip" {
  value = try(alicloud_instance.jumpbox[0].private_ip, null)
}

output "jumpbox_username" {
  value = var.jumpbox_username
}
