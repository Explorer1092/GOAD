#!/bin/bash

set -euo pipefail

DEFAULT_IMAGE_URL="https://downloads.openwrt.org/releases/24.10.5/targets/x86/64/openwrt-24.10.5-x86-64-generic-ext4-combined-efi.img.gz"
USE_ROUTER="${GOAD_VAGRANT_ESXI_USE_ROUTER:-no}"
BOX_NAME="${GOAD_VAGRANT_ESXI_ROUTER_BOX:-openwrt-24.10.5-x86-64-esxi}"
IMAGE_URL="${GOAD_OPENWRT_IMAGE_URL:-$DEFAULT_IMAGE_URL}"

if [ "$USE_ROUTER" != "yes" ]; then
  exit 0
fi

if vagrant box list | awk '{print $1}' | grep -Fxq "$BOX_NAME"; then
  echo "OpenWrt box '$BOX_NAME' already present, skipping."
  exit 0
fi

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing dependency: $1" >&2
    exit 1
  fi
}

require_cmd curl
require_cmd gzip
require_cmd qemu-img
require_cmd qemu-nbd
require_cmd lsblk
require_cmd tar
require_cmd kpartx

WORKDIR="$(mktemp -d)"
MOUNT_DIR="/mnt/openwrt"
NBD_DEV=""
MAPPER_DEV=""

cleanup() {
  if mountpoint -q "$MOUNT_DIR"; then
    sudo umount "$MOUNT_DIR" || true
  fi
  if [ -n "$MAPPER_DEV" ] && [ -n "$NBD_DEV" ]; then
    sudo kpartx -d "$NBD_DEV" || true
  fi
  if [ -n "$NBD_DEV" ]; then
    sudo qemu-nbd --disconnect "$NBD_DEV" || true
  fi
  rm -rf "$WORKDIR"
}

trap cleanup EXIT

echo "Downloading OpenWrt image..."
curl -fL -o "$WORKDIR/openwrt.img.gz" "$IMAGE_URL"
gzip -d "$WORKDIR/openwrt.img.gz"
IMG_PATH="$WORKDIR/openwrt.img"

sudo modprobe nbd max_part=8 || true
for dev in /dev/nbd*; do
  if sudo qemu-nbd --connect="$dev" "$IMG_PATH" 2>/dev/null; then
    NBD_DEV="$dev"
    break
  fi
done

if [ -z "$NBD_DEV" ]; then
  echo "No available /dev/nbd device found." >&2
  exit 1
fi

sudo partprobe "$NBD_DEV" || true
PART_PATH="$(lsblk -nrpo NAME,FSTYPE "$NBD_DEV" | awk '$2=="ext4"{print $1; exit}')"
if [ -z "$PART_PATH" ]; then
  sudo kpartx -a "$NBD_DEV"
  MAPPER_DEV="$(basename "$NBD_DEV")"
  PART_PATH="$(lsblk -nrpo NAME,FSTYPE /dev/mapper/"${MAPPER_DEV}"p* | awk '$2=="ext4"{print $1; exit}')"
fi

if [ -z "$PART_PATH" ]; then
  echo "Could not locate an ext4 partition in the OpenWrt image." >&2
  exit 1
fi

sudo mkdir -p "$MOUNT_DIR"
sudo mount "$PART_PATH" "$MOUNT_DIR"

sudo mkdir -p "$MOUNT_DIR/etc/uci-defaults"
sudo tee "$MOUNT_DIR/etc/uci-defaults/99-vmtools" >/dev/null <<'EOF'
#!/bin/sh

for i in $(seq 1 30); do
  ping -c1 -W1 1.1.1.1 >/dev/null 2>&1 && break
  sleep 2
done

if opkg update && opkg install open-vm-tools; then
  /etc/init.d/open-vm-tools enable
  /etc/init.d/open-vm-tools start
  exit 0
fi

exit 1
EOF
sudo chmod +x "$MOUNT_DIR/etc/uci-defaults/99-vmtools"
sync
sudo umount "$MOUNT_DIR"

if [ -n "$MAPPER_DEV" ]; then
  sudo kpartx -d "$NBD_DEV" || true
  MAPPER_DEV=""
fi
sudo qemu-nbd --disconnect "$NBD_DEV"
NBD_DEV=""

qemu-img convert -f raw -O vmdk -o subformat=monolithicSparse "$IMG_PATH" "$WORKDIR/openwrt.vmdk"

cat > "$WORKDIR/openwrt.vmx" <<'EOF'
.encoding = "UTF-8"
config.version = "8"
virtualHW.version = "14"
memsize = "256"
numvcpus = "1"
firmware = "efi"
scsi0.present = "TRUE"
scsi0.virtualDev = "lsilogic"
scsi0:0.present = "TRUE"
scsi0:0.fileName = "openwrt.vmdk"
scsi0:0.deviceType = "scsi-hardDisk"
ethernet0.present = "TRUE"
ethernet0.virtualDev = "e1000"
ethernet0.addressType = "generated"
EOF

echo '{"provider":"vmware_esxi"}' > "$WORKDIR/metadata.json"
tar -C "$WORKDIR" -czf "$WORKDIR/openwrt.box" metadata.json openwrt.vmx openwrt.vmdk

vagrant box add --name "$BOX_NAME" --provider vmware_esxi --architecture amd64 "$WORKDIR/openwrt.box"
