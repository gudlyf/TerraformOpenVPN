#!/bin/sh
# Runs inside the server container.
set -eu
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq python3-yaml iproute2 >/dev/null
python3 /work/apply-cloud-config.py /work/.out/user_data.yaml
# Equivalent of the runcmd entries (no systemd in a container).
/usr/local/sbin/openvpn-nat start
cd /etc/openvpn/server
exec openvpn --config server.conf
