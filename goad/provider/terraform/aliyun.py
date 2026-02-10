from goad.provider.terraform.terraform import TerraformProvider
from goad.utils import *
from goad.log import Log
import os
import time
import ipaddress


class AliyunProvider(TerraformProvider):
    provider_name = ALIYUN
    default_provisioner = PROVISIONING_REMOTE
    allowed_provisioners = [PROVISIONING_REMOTE]

    def __init__(self, lab_name, config):
        super().__init__(lab_name)
        self.jumpbox_setup_script = 'setup_aliyun.sh'
        self.region = config.get_value('aliyun', 'aliyun_region', 'ap-southeast-1')
        self.zone = config.get_value('aliyun', 'aliyun_zone', 'ap-southeast-1a')
        self.vpc_cidr = config.get_value('aliyun', 'aliyun_vpc_cidr', '10.0.0.0/16')
        vswitch_cidr = config.get_value('aliyun', 'aliyun_vswitch_cidr', '10.0.1.0/24')
        self.vswitch_cidrs = [vswitch_cidr] if isinstance(vswitch_cidr, str) else vswitch_cidr
        self.nat_gateway_enabled = str(config.get_value('aliyun', 'aliyun_nat_gateway_enabled', 'true')).lower() in ['1', 'true', 'yes', 'y']
        self.tag_prefix = config.get_value('aliyun', 'aliyun_tag_prefix', 'GOAD')
        self.tag = lab_name
        self.tags = {
            'Project': self.tag_prefix,
            'Lab': lab_name,
            'Provider': self.provider_name,
            'Instance': self.tag
        }
        self.image_use_custom_first = str(config.get_value('aliyun', 'aliyun_image_use_custom_first', 'true')).lower() in ['1', 'true', 'yes', 'y']
        self.windows_custom_image_id = config.get_value('aliyun', 'aliyun_windows_custom_image_id', '')
        self.windows_public_image_id = config.get_value('aliyun', 'aliyun_windows_public_image_id', '')
        self.linux_custom_image_id = config.get_value('aliyun', 'aliyun_linux_custom_image_id', '')
        self.linux_public_image_id = config.get_value('aliyun', 'aliyun_linux_public_image_id', '')
        self.windows_image_name_regex = config.get_value('aliyun', 'aliyun_windows_image_name_regex', 'Windows Server 2019')
        self.linux_image_name_regex = config.get_value('aliyun', 'aliyun_linux_image_name_regex', 'ubuntu_22_04')
        self.artifact_state = 'terraform.tfstate'
        self.artifact_plan = 'terraform.tfplan'

    def set_tag(self, tag):
        self.tag = tag
        self.tags['Instance'] = tag

    def _check_once(self):
        checks = [
            self.command.check_terraform(),
            self.command.check_rsync()
        ]
        valid = all(checks)

        missing = []
        if not self.region:
            missing.append('aliyun_region')
        if not self.zone:
            missing.append('aliyun_zone')
        if not self.vpc_cidr:
            missing.append('aliyun_vpc_cidr')
        if not self.vswitch_cidrs:
            missing.append('aliyun_vswitch_cidr')
        if missing:
            Log.error(f"Aliyun config missing: {', '.join(missing)}")
            valid = False

        try:
            vpc_network = ipaddress.ip_network(self.vpc_cidr)
            seen = []
            for cidr in self.vswitch_cidrs:
                subnet = ipaddress.ip_network(cidr)
                if not subnet.subnet_of(vpc_network):
                    Log.error(f'vSwitch CIDR {cidr} not within VPC CIDR {self.vpc_cidr}')
                    valid = False
                for existing in seen:
                    if subnet.overlaps(existing):
                        Log.error(f'vSwitch CIDR {cidr} overlaps with {existing}')
                        valid = False
                seen.append(subnet)
        except ValueError as exc:
            Log.error(f'CIDR validation failed: {exc}')
            valid = False

        windows_image_ok = bool(self.windows_custom_image_id or self.windows_public_image_id or self.windows_image_name_regex)
        linux_image_ok = bool(self.linux_custom_image_id or self.linux_public_image_id or self.linux_image_name_regex)
        if self.image_use_custom_first:
            if not windows_image_ok:
                Log.error('Missing Windows image id or name regex')
                valid = False
            if not linux_image_ok:
                Log.error('Missing Linux image id or name regex')
                valid = False
        else:
            if not (self.windows_public_image_id or self.windows_image_name_regex):
                Log.error('Missing Windows public image id or name regex')
                valid = False
            if not (self.linux_public_image_id or self.linux_image_name_regex):
                Log.error('Missing Linux public image id or name regex')
                valid = False

        access_key = os.environ.get('ALICLOUD_ACCESS_KEY') or os.environ.get('ALICLOUD_ACCESS_KEY_ID')
        secret_key = os.environ.get('ALICLOUD_SECRET_KEY') or os.environ.get('ALICLOUD_ACCESS_KEY_SECRET')
        if not access_key or not secret_key:
            Log.error('Aliyun credentials not found in environment (ALICLOUD_ACCESS_KEY/SECRET_KEY)')
            valid = False

        return valid

    def check(self):
        for attempt in range(1, 4):
            if self._check_once():
                return True
            Log.warning(f'Aliyun preflight failed, retry {attempt}/3')
            time.sleep(2 * attempt)
        return False

    def _run_terraform_with_retry(self, args, retries=3, delay=5):
        attempt = 0
        while attempt < retries:
            attempt += 1
            result = self.command.run_terraform(args, self.path)
            if result:
                return True
            if attempt < retries:
                Log.warning(f"Terraform {' '.join(args)} failed, retry {attempt}/{retries}")
                time.sleep(delay * attempt)
        return False

    def install(self):
        if not self._run_terraform_with_retry(['init']):
            return False
        if not self._run_terraform_with_retry(['plan']):
            return False
        result = self._run_terraform_with_retry(['apply'])
        report_path = os.path.join(self.path, 'aliyun-validation-report.txt')
        try:
            with open(report_path, 'w') as report:
                report.write('Aliyun validation report\n')
                report.write(f'Lab: {self.tag}\n')
                report.write('Validation pending: run provisioning and verify domain join.\n')
        except OSError:
            Log.warning('Unable to write validation report')
        return result

    def destroy(self):
        result = self._run_terraform_with_retry(['destroy'])
        report_path = os.path.join(self.path, 'aliyun-destroy-report.txt')
        try:
            with open(report_path, 'w') as report:
                report.write('Aliyun destroy summary\n')
                report.write(f'Lab: {self.tag}\n')
                report.write(f'Tag prefix: {self.tag_prefix}\n')
                report.write('If resources remain, filter by tags (Project/Lab/Provider/Instance) and delete manually.\n')
        except OSError:
            Log.warning('Unable to write destroy report')
        return result

    def get_jumpbox_ip(self, ip_range=''):
        jumpbox_ip = self.command.run_terraform_output(['jumpbox_public_ip'], self.path)
        if jumpbox_ip is None:
            Log.error('Jump box ip not found')
            return None
        if not Utils.is_valid_ipv4(jumpbox_ip):
            Log.error('Invalid IP')
            return None
        return jumpbox_ip
