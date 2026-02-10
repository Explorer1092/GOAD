#!/usr/bin/env python3
import hashlib
import re
import sys


def mac_for(name, suffix):
    digest = hashlib.md5(f"{name}-{suffix}".encode('utf-8')).hexdigest()
    b0 = int(digest[0:2], 16) & 0x3f
    b1 = int(digest[2:4], 16)
    b2 = int(digest[4:6], 16)
    return f"00:50:56:{b0:02x}:{b1:02x}:{b2:02x}"


def parse_boxes(vagrantfile_path):
    with open(vagrantfile_path, 'r', encoding='utf-8') as handle:
        content = handle.read()
    pattern = re.compile(r'\{\s*:name\s*=>\s*"([^"]+)",\s*:ip\s*=>\s*"([0-9.]+)"', re.MULTILINE)
    boxes = []
    for name, ip in pattern.findall(content):
        boxes.append((name, ip))
    return boxes


def main():
    if len(sys.argv) != 2:
        print("Usage: scripts/esxi_openwrt_dhcp_hosts.py <path/to/Vagrantfile>")
        return 2
    vagrantfile_path = sys.argv[1]
    boxes = parse_boxes(vagrantfile_path)
    if not boxes:
        print("No boxes found. Check the Vagrantfile path.")
        return 1

    for name, ip in boxes:
        if name in ("GOAD-ROUTER", "PROVISIONING"):
            continue
        mac = mac_for(name, 'lan')
        print("uci add dhcp host")
        print(f"uci set dhcp.@host[-1].name='{name}'")
        print(f"uci set dhcp.@host[-1].ip='{ip}'")
        print(f"uci set dhcp.@host[-1].mac='{mac}'")
    print("uci commit dhcp")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
