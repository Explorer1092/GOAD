from goad.provider.vagrant.vagrant import VagrantProvider
from goad.utils import *


class VmwareVcenterProvider(VagrantProvider):
    provider_name = VMWARE_VCENTER
    default_provisioner = PROVISIONING_LOCAL
    allowed_provisioners = [PROVISIONING_LOCAL, PROVISIONING_RUNNER, PROVISIONING_DOCKER, PROVISIONING_VM]

    def check(self):
        checks = [
            super().check(),
            self.command.check_vagrant_plugin('vagrant-vsphere', True),
            self.command.check_vagrant_plugin('vagrant-env', True)
        ]
        return all(checks)
