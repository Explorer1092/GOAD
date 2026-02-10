resource "alicloud_security_group" "goad" {
  name        = "${local.lab_identifier}-sg"
  description = "GOAD lab security group"
  vpc_id      = alicloud_vpc.goad.id
  tags        = local.tags
}

# Allow intra-VPC traffic
resource "alicloud_security_group_rule" "intra_allow" {
  type              = "ingress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  priority          = 1
  security_group_id = alicloud_security_group.goad.id
  cidr_ip           = var.vpc_cidr
  description       = "Allow intra-VPC traffic"
}

# Default egress allow
resource "alicloud_security_group_rule" "egress_allow" {
  type              = "egress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  priority          = 1
  security_group_id = alicloud_security_group.goad.id
  cidr_ip           = "0.0.0.0/0"
  description       = "Allow all egress (uses NAT if enabled)"
}
