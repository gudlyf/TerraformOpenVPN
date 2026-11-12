#!/bin/sh
# Runs inside the client container. $1 is the .ovpn profile to use.
set -eu
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq openvpn iproute2 iputils-ping curl >/dev/null
openvpn --config "$1" --log /tmp/client.log --daemon
for _ in $(seq 1 60); do
  if grep -q "Initialization Sequence Completed" /tmp/client.log; then
    break
  fi
  if grep -qE "AUTH_FAILED|TLS Error|Exiting due to fatal error" /tmp/client.log; then
    cat /tmp/client.log
    exit 1
  fi
  sleep 1
done
cat /tmp/client.log
grep -q "Initialization Sequence Completed" /tmp/client.log
echo "--- routes"
ip route
echo "--- ping VPN gateway"
ping -c 3 -W 2 10.8.0.1
echo "--- egress through tunnel (NAT)"
ip route get 1.1.1.1 | grep -q "dev tun0"
curl -sS --max-time 15 https://checkip.amazonaws.com
echo "CLIENT OK"
