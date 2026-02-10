import os
import re
import shlex
import subprocess

from goad.log import Log
from goad.provider.vagrant.vagrant import VagrantProvider
from goad.utils import *


class VmwareEsxiProvider(VagrantProvider):
    provider_name = VMWARE_ESXI
    default_provisioner = PROVISIONING_LOCAL
    allowed_provisioners = [PROVISIONING_LOCAL, PROVISIONING_RUNNER, PROVISIONING_DOCKER, PROVISIONING_VM]

    def __init__(self, lab_name, config=None):
        super().__init__(lab_name)
        self.jumpbox = None
        self.use_jumpbox_vagrant = False
        self.remote_project_path = '/home/vagrant/GOAD'

    def set_jumpbox(self, jumpbox):
        self.jumpbox = jumpbox

    def set_jumpbox_vagrant(self, enabled):
        self.use_jumpbox_vagrant = enabled

    def check(self):
        checks = [
            super().check(),
            self.command.check_vagrant_plugin('vagrant-vmware-esxi', True),
            self.command.check_vagrant_plugin('vagrant-env', True),
            self.command.check_ovftool()
        ]
        return all(checks)

    def _get_instance_id(self):
        if self.path is None:
            return None
        return os.path.basename(os.path.dirname(self.path))

    def _run_vagrant_local(self, args):
        args_str = ' '.join(shlex.quote(arg) for arg in args)
        envfile = os.path.join(self.path, '.env')
        if os.path.isfile(envfile):
            command = f"bash -lc 'source .env && vagrant {args_str}'"
        else:
            command = f"vagrant {args_str}"
        return self.command.run_command(command, self.path)

    def _get_jumpbox_wan_ip(self, jumpbox_name='PROVISIONING'):
        args_str = shlex.quote(jumpbox_name)
        envfile = os.path.join(self.path, '.env')
        if os.path.isfile(envfile):
            command = f"bash -lc 'source .env && vagrant address {args_str}'"
        else:
            command = f"vagrant address {args_str}"
        result = subprocess.run(command, cwd=self.path, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if result.returncode != 0:
            Log.error(f'Failed to get jumpbox WAN IP: {result.stderr.strip()}')
            return None
        ip_match = re.findall(r'\\b(?:\\d{1,3}\\.){3}\\d{1,3}\\b', result.stdout)
        if not ip_match:
            Log.error('Jumpbox WAN IP not found in vagrant address output')
            return None
        return ip_match[-1]

    def _get_box_names(self):
        vagrantfile = os.path.join(self.path, 'Vagrantfile')
        if not os.path.isfile(vagrantfile):
            Log.error(f'Vagrantfile not found: {vagrantfile}')
            return []
        with open(vagrantfile, 'r', encoding='utf-8') as handle:
            content = handle.read()
        names = re.findall(r':name\s*=>\s*"([^"]+)"', content)
        seen = set()
        unique_names = []
        for name in names:
            if name not in seen:
                unique_names.append(name)
                seen.add(name)
        return unique_names

    def _split_box_names(self):
        names = self._get_box_names()
        jumpbox_name = 'PROVISIONING' if 'PROVISIONING' in names else None
        router_name = 'GOAD-ROUTER' if 'GOAD-ROUTER' in names else None
        other_names = [name for name in names if name not in [jumpbox_name, router_name]]
        return jumpbox_name, router_name, other_names

    def _ensure_jumpbox_vm(self, jumpbox_name):
        if not jumpbox_name:
            Log.error('No jumpbox target found for local Vagrant run')
            return False
        return self._run_vagrant_local(['up', jumpbox_name])

    def _ensure_openwrt_box(self):
        if self.jumpbox is None:
            return False
        instance_id = self._get_instance_id()
        if instance_id is None:
            Log.error('Instance id not found for OpenWrt box build')
            return False
        remote_path = f'{self.remote_project_path}/workspace/{instance_id}/provider'
        command = "bash -lc 'source .env && /home/vagrant/GOAD/scripts/build_openwrt_esxi_box.sh'"
        return self.jumpbox.run_command(command, remote_path)

    def _prepare_jumpbox(self):
        if self.jumpbox is None:
            Log.error('Jumpbox is not configured')
            return False
        if self.use_jumpbox_vagrant:
            wan_ip = self._get_jumpbox_wan_ip()
            if wan_ip is None:
                Log.error('Unable to resolve jumpbox WAN IP')
                return False
            self.jumpbox.ip = wan_ip
        self.jumpbox.ssh_key = self.jumpbox.get_jumpbox_key()
        if self.jumpbox.ssh_key is None or not os.path.isfile(self.jumpbox.ssh_key):
            Log.error('Jumpbox SSH key not found')
            return False
        self.jumpbox.provision()
        if hasattr(self.jumpbox, 'sync_repo_sources'):
            self.jumpbox.sync_repo_sources()
        else:
            self.jumpbox.sync_sources()
        if self.use_jumpbox_vagrant:
            if not self._ensure_openwrt_box():
                return False
        return True

    def _run_jumpbox_vagrant(self, args):
        if self.jumpbox is None:
            Log.error('Jumpbox is not configured')
            return False
        instance_id = self._get_instance_id()
        if instance_id is None:
            Log.error('Instance id not found for jumpbox Vagrant run')
            return False
        remote_path = f'{self.remote_project_path}/workspace/{instance_id}/provider'
        args_str = ' '.join(args)
        command = f"bash -lc 'source .env && vagrant {args_str}'"
        return self.jumpbox.run_command(command, remote_path)

    def _run_split_vagrant(self, args):
        jumpbox_name, router_name, other_names = self._split_box_names()
        ok = True
        local_targets = [jumpbox_name] if jumpbox_name else []
        remote_targets = []
        if router_name:
            remote_targets.append(router_name)
        remote_targets.extend(other_names)
        if local_targets:
            ok = self._run_vagrant_local(args + local_targets) and ok
        if remote_targets:
            if not self._prepare_jumpbox():
                return False
            ok = self._run_jumpbox_vagrant(args + remote_targets) and ok
        return ok

    def _run_vm_command(self, action, vm_name):
        jumpbox_name, _router_name, _other_names = self._split_box_names()
        if vm_name == jumpbox_name:
            return self._run_vagrant_local([action, vm_name])
        if not self._prepare_jumpbox():
            return False
        return self._run_jumpbox_vagrant([action, vm_name])

    def get_jumpbox_ip(self, ip_range=''):
        if self.use_jumpbox_vagrant:
            wan_ip = self._get_jumpbox_wan_ip()
            if wan_ip is not None:
                return wan_ip
        return super().get_jumpbox_ip(ip_range)

    def install(self):
        if not self.use_jumpbox_vagrant:
            return self._run_vagrant_local(['up'])
        jumpbox_name, router_name, other_names = self._split_box_names()
        if not jumpbox_name:
            Log.error('PROVISIONING VM not found in Vagrantfile; set provisioner to "vm"')
            return False
        if not self._ensure_jumpbox_vm(jumpbox_name):
            return False
        if not self._prepare_jumpbox():
            return False
        if router_name:
            if not self._run_jumpbox_vagrant(['up', router_name]):
                return False
        if not other_names:
            return True
        return self._run_jumpbox_vagrant(['up'] + other_names)

    def start(self):
        if not self.use_jumpbox_vagrant:
            return self._run_vagrant_local(['up'])
        return self._run_split_vagrant(['up'])

    def stop(self):
        if not self.use_jumpbox_vagrant:
            return self._run_vagrant_local(['halt'])
        return self._run_split_vagrant(['halt'])

    def destroy(self):
        if not self.use_jumpbox_vagrant:
            return self._run_vagrant_local(['destroy'])
        return self._run_split_vagrant(['destroy'])

    def status(self):
        if not self.use_jumpbox_vagrant:
            return self._run_vagrant_local(['status'])
        return self._run_split_vagrant(['status'])

    def start_vm(self, vm_name):
        if not self.use_jumpbox_vagrant:
            return self._run_vagrant_local(['up', vm_name])
        return self._run_vm_command('up', vm_name)

    def stop_vm(self, vm_name):
        if not self.use_jumpbox_vagrant:
            return self._run_vagrant_local(['halt', vm_name])
        return self._run_vm_command('halt', vm_name)

    def destroy_vm(self, vm_name):
        if not self.use_jumpbox_vagrant:
            return self._run_vagrant_local(['destroy', vm_name])
        return self._run_vm_command('destroy', vm_name)
