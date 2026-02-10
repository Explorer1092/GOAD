#!/bin/bash

set -e

# Install base dependencies
sudo apt-get update
sudo apt-get install -y git python3-venv python3-pip curl gpg rsync qemu-utils kpartx

# Clone or update GOAD
GOAD_REPO=/home/vagrant/GOAD
GIT_FOLDER=$GOAD_REPO/.git
if [ ! -d $GIT_FOLDER ]
then
    rm -rf $GOAD_REPO
    git clone https://github.com/Orange-Cyberdefense/GOAD.git $GOAD_REPO
    cd $GOAD_REPO
else
    cd $GOAD_REPO
    git pull
fi

# Install ansible and pywinrm
python3 -m pip install --upgrade pip
cd $GOAD_REPO
python3 -m pip install -r requirements.yml

cd $GOAD_REPO/ansible
/home/vagrant/.local/bin/ansible-galaxy install -r requirements.yml

# Install Vagrant (HashiCorp repo)
if ! command -v vagrant >/dev/null 2>&1; then
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
    sudo apt-get update
    sudo apt-get install -y vagrant
fi

# Vagrant plugins
vagrant plugin install vagrant-vmware-esxi
vagrant plugin install vagrant-reload

# OVF Tool is required for vmware_esxi provider
if ! command -v ovftool >/dev/null 2>&1; then
    echo "ovftool is missing. Install the Linux OVF Tool bundle on this jumpbox."
    echo "Example: sudo sh /path/to/VMware-ovftool-*.bundle --eulas-agreed --required"
fi

# set color
sudo sed -i '/force_color_prompt=yes/s/^#//g' /home/*/.bashrc
sudo sed -i '/force_color_prompt=yes/s/^#//g' /root/.bashrc
