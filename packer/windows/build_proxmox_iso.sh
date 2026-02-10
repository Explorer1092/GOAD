#!/bin/bash

# transform files into iso, because proxmox only accept iso and no floppy A:\

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
ISO_DIR="${BASE_DIR}/iso"
VAR_DIR="${BASE_DIR}/vars/proxmox"
ANSWER_DIR="${BASE_DIR}/answer_files/proxmox"
SCRIPTS_DIR="${BASE_DIR}/scripts"

mkdir -p "${ISO_DIR}"

echo "[+] Build iso windows 10 with cloudinit"
mkisofs -J -l -R -V "autounatend CD" -iso-level 4 -o "${ISO_DIR}/Autounattend_windows10_cloudinit.iso" "${ANSWER_DIR}/windows_10/cloudinit/en-US"
sha_win10=$(sha256sum "${ISO_DIR}/Autounattend_windows10_cloudinit.iso" | cut -d ' ' -f1)
echo "[+] update windows_10_22h2_cloudinit.pkrvars.hcl"
sed -i "s/\"sha256:.*\"/\"sha256:${sha_win10}\"/g" "${VAR_DIR}/windows_10_22h2_cloudinit.pkrvars.hcl"

echo "[+] Build iso windows 10 with cloudinit and update"
mkisofs -J -l -R -V "autounatend CD" -iso-level 4 -o "${ISO_DIR}/Autounattend_windows10_cloudinit_uptodate.iso" "${ANSWER_DIR}/windows_10/cloudinit_uptodate/en-US"
sha_win10=$(sha256sum "${ISO_DIR}/Autounattend_windows10_cloudinit_uptodate.iso" | cut -d ' ' -f1)
echo "[+] update windows_10_22h2_cloudinit_uptodate.pkrvars.hcl"
sed -i "s/\"sha256:.*\"/\"sha256:${sha_win10}\"/g" "${VAR_DIR}/windows_10_22h2_cloudinit_uptodate.pkrvars.hcl"

echo "[+] Build iso winserver2016 with cloudinit"
mkisofs -J -l -R -V "autounatend CD" -iso-level 4 -o "${ISO_DIR}/Autounattend_winserver2016_cloudinit.iso" "${ANSWER_DIR}/windows_server_2016/cloudinit/en-US-fr-FR"
sha_winserv2016=$(sha256sum "${ISO_DIR}/Autounattend_winserver2016_cloudinit.iso" | cut -d ' ' -f1)
echo "[+] update windows_server2016_cloudinit.pkrvars.hcl"
sed -i "s/\"sha256:.*\"/\"sha256:${sha_winserv2016}\"/g" "${VAR_DIR}/windows_server2016_cloudinit.pkrvars.hcl"

echo "[+] Build iso winserver2019 with cloudinit"
mkisofs -J -l -R -V "autounatend CD" -iso-level 4 -o "${ISO_DIR}/Autounattend_winserver2019_cloudinit.iso" "${ANSWER_DIR}/windows_server_2019/cloudinit/en-US-fr-FR"
sha_winserv2019=$(sha256sum "${ISO_DIR}/Autounattend_winserver2019_cloudinit.iso" | cut -d ' ' -f1)
echo "[+] update windows_server2019_cloudinit.pkrvars.hcl"
sed -i "s/\"sha256:.*\"/\"sha256:${sha_winserv2019}\"/g" "${VAR_DIR}/windows_server2019_cloudinit.pkrvars.hcl"

echo "[+] Build iso winserver2019 with cloudinit and update"
mkisofs -J -l -R -V "autounatend CD" -iso-level 4 -o "${ISO_DIR}/Autounattend_winserver2019_cloudinit_uptodate.iso" "${ANSWER_DIR}/windows_server_2019/cloudinit_uptodate/en-US-fr-FR"
sha_winserv2019_update=$(sha256sum "${ISO_DIR}/Autounattend_winserver2019_cloudinit_uptodate.iso" | cut -d ' ' -f1)
echo "[+] update windows_server2019_cloudinit_uptodate.pkrvars.hcl"
sed -i "s/\"sha256:.*\"/\"sha256:${sha_winserv2019_update}\"/g" "${VAR_DIR}/windows_server2019_cloudinit_uptodate.pkrvars.hcl"

echo "[+] Build iso for scripts"
# Graft common and proxmox scripts into the ISO root
mkisofs -J -l -R -V "scripts CD" -iso-level 4 -o "${ISO_DIR}/scripts_withcloudinit.iso" \
  -graft-points \
  ConfigureRemotingForAnsible.ps1="${SCRIPTS_DIR}/common/ConfigureRemotingForAnsible.ps1" \
  disable-screensaver.ps1="${SCRIPTS_DIR}/common/disable-screensaver.ps1" \
  disable-winrm.ps1="${SCRIPTS_DIR}/common/disable-winrm.ps1" \
  fixnetwork.ps1="${SCRIPTS_DIR}/common/fixnetwork.ps1" \
  microsoft-updates.bat="${SCRIPTS_DIR}/common/microsoft-updates.bat" \
  enable-winrm.ps1="${SCRIPTS_DIR}/common/enable-winrm.ps1" \
  win-updates.ps1="${SCRIPTS_DIR}/common/win-updates.ps1" \
  set-proxy.ps1="${SCRIPTS_DIR}/proxmox/set-proxy.ps1" \
  Install-WMF3Hotfix.ps1="${SCRIPTS_DIR}/proxmox/Install-WMF3Hotfix.ps1" \
  sysprep="${SCRIPTS_DIR}/proxmox/sysprep"
# echo "scripts_withcloudinit.iso"
# sha256sum "${ISO_DIR}/scripts_withcloudinit.iso"
