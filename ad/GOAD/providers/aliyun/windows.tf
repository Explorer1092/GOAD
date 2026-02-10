# 2 vCPU / 8GB
"dc01" = {
  name               = "dc01"
  image_id           = ""
  image_name_regex   = "win2019_1809_x64_dtc_zh-cn_40G_alibase_.*"
  cpu                = 2
  memory_gb          = 8
  private_ip_address = "{{ip_range}}.10"
  password           = "8dCT-DJjgScp"
}
"dc02" = {
  name               = "dc02"
  image_id           = ""
  image_name_regex   = "win2019_1809_x64_dtc_zh-cn_40G_alibase_.*"
  cpu                = 2
  memory_gb          = 8
  private_ip_address = "{{ip_range}}.11"
  password           = "NgtI75cKV+Pu"
}
"dc03" = {
  name               = "dc03"
  image_id           = ""
  image_name_regex   = "win2019_1809_x64_dtc_zh-cn_40G_alibase_.*"
  cpu                = 2
  memory_gb          = 8
  private_ip_address = "{{ip_range}}.12"
  password           = "Ufe-bVXSx9rk"
}
"srv02" = {
  name               = "srv02"
  image_id           = ""
  image_name_regex   = "win2019_1809_x64_dtc_zh-cn_40G_alibase_.*"
  cpu                = 2
  memory_gb          = 8
  private_ip_address = "{{ip_range}}.22"
  password           = "NgtI75cKV+Pu"
}
"srv03" = {
  name               = "srv03"
  image_id           = ""
  image_name_regex   = "win2019_1809_x64_dtc_zh-cn_40G_alibase_.*"
  cpu                = 2
  memory_gb          = 8
  private_ip_address = "{{ip_range}}.23"
  password           = "978i2pF43UJ-"
}
