variable "linux_vm_config" {
  type = map(object({
    name               = string
    image_id           = string
    image_name_regex   = string
    cpu                = number
    memory_gb          = number
    private_ip_address = string
    password           = string
  }))

  default = {
    {{linux_vms}}
  }
}

locals {
  linux_image_id = (
    var.image_use_custom_first && length(var.linux_custom_image_id) > 0 ? var.linux_custom_image_id :
    (!var.image_use_custom_first && length(var.linux_public_image_id) > 0 ? var.linux_public_image_id :
    var.linux_public_image_id)
  )
}

data "alicloud_images" "linux" {
  for_each = var.linux_vm_config

  owners       = length(var.linux_image_owner) > 0 ? var.linux_image_owner : var.image_owner
  os_type      = "linux"
  name_regex   = length(each.value.image_name_regex) > 0 ? each.value.image_name_regex : var.linux_image_name_regex
  most_recent  = true
  architecture = "x86_64"
}

data "alicloud_instance_types" "linux" {
  for_each = var.linux_vm_config

  availability_zone = var.zone
  cpu_core_count    = each.value.cpu
  memory_size       = each.value.memory_gb
}

resource "alicloud_instance" "linux" {
  for_each = var.linux_vm_config

  availability_zone       = var.zone
  vswitch_id              = local.primary_vswitch_id
  security_groups         = [alicloud_security_group.goad.id]
  private_ip              = each.value.private_ip_address
  instance_type           = data.alicloud_instance_types.linux[each.key].ids[0]
  image_id                = length(each.value.image_id) > 0 ? each.value.image_id : (length(local.linux_image_id) > 0 ? local.linux_image_id : data.alicloud_images.linux[each.key].images[0].id)
  password                = each.value.password
  internet_max_bandwidth_out = 0
  system_disk_category    = "cloud_efficiency"
  system_disk_size        = 50
  instance_name           = "${local.lab_identifier}-${each.value.name}"
  host_name               = each.value.name
  tags = merge(local.tags, {
    Name = "${local.lab_identifier}-${each.value.name}"
    Role = each.value.name
  })
}
