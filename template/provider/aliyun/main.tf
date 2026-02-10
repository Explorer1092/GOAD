terraform {
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1.214.0"
    }
  }

  required_version = ">= 1.5.0"
}

provider "alicloud" {
  region = var.region
}

locals {
  lab_identifier = "{{lab_identifier}}"
  tags = merge({
    Project  = var.tag_prefix
    Lab      = "{{lab_name}}"
    Provider = "aliyun"
    Instance = "{{lab_identifier}}"
  }, var.additional_tags)
}
