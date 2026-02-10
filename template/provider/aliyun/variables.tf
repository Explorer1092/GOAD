variable "region" {
  description = "Aliyun region to deploy GOAD"
  type        = string
  default     = "{{config.get_value('aliyun', 'aliyun_region', 'ap-southeast-1')}}"
}

variable "zone" {
  description = "Aliyun zone to deploy GOAD"
  type        = string
  default     = "{{config.get_value('aliyun', 'aliyun_zone', 'ap-southeast-1a')}}"
}

variable "vpc_cidr" {
  description = "CIDR for dedicated VPC"
  type        = string
  default     = "{{config.get_value('aliyun', 'aliyun_vpc_cidr', '10.0.0.0/16')}}"
  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid CIDR block."
  }
}

variable "vswitch_cidrs" {
  description = "CIDRs for vSwitch subnets"
  type        = list(string)
  default     = ["{{config.get_value('aliyun', 'aliyun_vswitch_cidr', '10.0.1.0/24')}}"]
  validation {
    condition     = alltrue([for cidr in var.vswitch_cidrs : can(cidrnetmask(cidr))])
    error_message = "vswitch_cidrs must be a list of valid CIDR blocks."
  }
}

variable "nat_gateway_enabled" {
  description = "Create NAT gateway for outbound access"
  type        = bool
  default     = true
}

variable "jumpbox_enabled" {
  description = "Create jumpbox with public access for remote provisioning"
  type        = bool
  default     = true
}

variable "jumpbox_private_ip" {
  description = "Private IP for jumpbox"
  type        = string
  default     = "{{ip_range}}.100"
}

variable "jumpbox_instance_type" {
  description = "Instance type for jumpbox"
  type        = string
  default     = "ecs.g6.large"
}

variable "jumpbox_disk_size" {
  description = "Jumpbox system disk size (GB)"
  type        = number
  default     = 40
}

variable "jumpbox_whitelist_cidrs" {
  description = "CIDRs allowed to SSH into jumpbox"
  type        = set(string)
  default     = ["0.0.0.0/0"]
}

variable "jumpbox_username" {
  description = "SSH username for jumpbox"
  type        = string
  default     = "goad"
}

variable "tag_prefix" {
  description = "Project tag value prefix"
  type        = string
  default     = "{{config.get_value('aliyun', 'aliyun_tag_prefix', 'GOAD')}}"
}

variable "additional_tags" {
  description = "Optional extra tags merged into defaults"
  type        = map(string)
  default     = {}
}

variable "image_use_custom_first" {
  description = "Prefer custom (Packer) images; fallback to public image IDs if custom is empty"
  type        = bool
  default     = true
}

variable "image_owner" {
  description = "Aliyun image owner filter (system/public/custom account)"
  type        = string
  default     = "{{config.get_value('aliyun', 'aliyun_image_owner', 'system')}}"
}

variable "windows_image_owner" {
  description = "Aliyun Windows image owner override (optional)"
  type        = string
  default     = "{{config.get_value('aliyun', 'aliyun_windows_image_owner', '')}}"
}

variable "linux_image_owner" {
  description = "Aliyun Linux image owner override (optional)"
  type        = string
  default     = "{{config.get_value('aliyun', 'aliyun_linux_image_owner', '')}}"
}

variable "windows_image_name_regex" {
  description = "Regex for public Windows image name (used when image IDs are empty)"
  type        = string
  default     = "{{config.get_value('aliyun', 'aliyun_windows_image_name_regex', 'win2019_1809_x64_dtc_zh-cn_40G_alibase_.*')}}"
}

variable "windows_custom_image_id" {
  description = "Custom Windows image ID (Packer output)"
  type        = string
  default     = "{{config.get_value('aliyun', 'aliyun_windows_custom_image_id', '')}}"
}

variable "windows_public_image_id" {
  description = "Fallback public Windows image ID"
  type        = string
  # Use name regex to resolve system image automatically when IDs are empty.
  default     = "{{config.get_value('aliyun', 'aliyun_windows_public_image_id', '')}}"
  validation {
    condition = (
      length(var.windows_image_name_regex) > 0 ||
      (var.image_use_custom_first && (length(var.windows_custom_image_id) > 0 || length(var.windows_public_image_id) > 0)) ||
      (!var.image_use_custom_first && length(var.windows_public_image_id) > 0)
    )
    error_message = "Provide a Windows image ID or a public image name regex."
  }
}

variable "linux_custom_image_id" {
  description = "Custom Linux image ID (Packer output)"
  type        = string
  default     = "{{config.get_value('aliyun', 'aliyun_linux_custom_image_id', '')}}"
}

variable "linux_image_name_regex" {
  description = "Regex for public Linux image name (used when image IDs are empty)"
  type        = string
  default     = "{{config.get_value('aliyun', 'aliyun_linux_image_name_regex', 'ubuntu_22_04')}}"
}

variable "linux_public_image_id" {
  description = "Fallback public Linux image ID"
  type        = string
  default     = "{{config.get_value('aliyun', 'aliyun_linux_public_image_id', '')}}"
  validation {
    condition = (
      length(var.linux_image_name_regex) > 0 ||
      (var.image_use_custom_first && (length(var.linux_custom_image_id) > 0 || length(var.linux_public_image_id) > 0)) ||
      (!var.image_use_custom_first && length(var.linux_public_image_id) > 0)
    )
    error_message = "Provide a Linux image ID or a public image name regex."
  }
}
