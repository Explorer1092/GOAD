variable "vm_config" {
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
    {{windows_vms}}
  }
}

locals {
  windows_image_id = (
    var.image_use_custom_first && length(var.windows_custom_image_id) > 0 ? var.windows_custom_image_id :
    (!var.image_use_custom_first && length(var.windows_public_image_id) > 0 ? var.windows_public_image_id :
    var.windows_public_image_id)
  )

  # WinRM bootstrap script template for Windows instances
  # PASSWORD_PLACEHOLDER will be replaced with actual password per instance
  winrm_bootstrap_template = <<-POWERSHELL
<powershell>
$ErrorActionPreference = "SilentlyContinue"
$logFile = "C:\winrm_bootstrap.log"

function Log($msg) {
  "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $msg" | Out-File -Append $logFile
}

Log "Starting WinRM bootstrap..."

# Wait for network
Start-Sleep -Seconds 30

# Enable Administrator account
Log "Enabling Administrator account..."
net user Administrator /active:yes
net user Administrator "PASSWORD_PLACEHOLDER"

# Create ansible user
Log "Creating ansible user..."
$ansibleUser = "ansible"
$ansiblePassword = "PASSWORD_PLACEHOLDER"
net user $ansibleUser $ansiblePassword /add 2>$null
net localgroup Administrators $ansibleUser /add 2>$null
Log "Ansible user created"

# Configure WinRM
Log "Configuring WinRM..."
winrm quickconfig -q
Enable-PSRemoting -Force
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true";Negotiate="true"}'
winrm set winrm/config/client/auth '@{Basic="true"}'

# Ensure HTTP listener exists
$httpListener = Get-ChildItem WSMan:\localhost\Listener -ErrorAction SilentlyContinue | Where-Object { $_.Keys -contains "Transport=HTTP" }
if (-not $httpListener) {
  Log "Creating HTTP listener..."
  winrm create winrm/config/Listener?Address=*+Transport=HTTP
}

# Configure firewall
Log "Configuring firewall..."
netsh advfirewall firewall add rule name="WinRM HTTP" protocol=TCP dir=in localport=5985 action=allow
netsh advfirewall firewall add rule name="WinRM HTTPS" protocol=TCP dir=in localport=5986 action=allow

# Disable UAC remote restrictions
Log "Disabling UAC remote restrictions..."
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "LocalAccountTokenFilterPolicy" -Value 1 -PropertyType DWord -Force

# Set WinRM service to automatic and restart
Log "Restarting WinRM service..."
Set-Service WinRM -StartupType Automatic
Restart-Service WinRM -Force

Log "WinRM bootstrap completed successfully!"
</powershell>
POWERSHELL
}

data "alicloud_images" "windows" {
  for_each = var.vm_config

  owners      = length(var.windows_image_owner) > 0 ? var.windows_image_owner : var.image_owner
  os_type     = "windows"
  name_regex  = length(each.value.image_name_regex) > 0 ? each.value.image_name_regex : var.windows_image_name_regex
  most_recent = true
}

data "alicloud_instance_types" "windows" {
  for_each = var.vm_config

  availability_zone = var.zone
  cpu_core_count    = each.value.cpu
  memory_size       = each.value.memory_gb
}

resource "alicloud_instance" "windows" {
  for_each = var.vm_config

  availability_zone       = var.zone
  vswitch_id              = local.primary_vswitch_id
  security_groups         = [alicloud_security_group.goad.id]
  private_ip              = each.value.private_ip_address
  instance_type           = data.alicloud_instance_types.windows[each.key].ids[0]
  image_id                = length(each.value.image_id) > 0 ? each.value.image_id : (length(local.windows_image_id) > 0 ? local.windows_image_id : data.alicloud_images.windows[each.key].images[0].id)
  password                = each.value.password
  internet_max_bandwidth_out = 0
  system_disk_category    = "cloud_efficiency"
  system_disk_size        = 80
  instance_name           = "${local.lab_identifier}-${each.value.name}"
  host_name               = each.value.name
  resource_group_id       = null
  user_data               = base64encode(replace(local.winrm_bootstrap_template, "PASSWORD_PLACEHOLDER", each.value.password))
  tags = merge(local.tags, {
    Name = "${local.lab_identifier}-${each.value.name}"
    Role = each.value.name
  })
}
