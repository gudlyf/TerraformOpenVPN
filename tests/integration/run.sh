#!/usr/bin/env bash
# End-to-end test of modules/openvpn-config using Docker:
#   1. Render the configuration with Terraform (no cloud credentials needed).
#   2. Bootstrap an Ubuntu 24.04 "server" container from the generated cloud-init.
#   3. Connect a client container with a generated .ovpn and route traffic
#      through the tunnel.
#   4. Check that a client whose ccd file is missing is refused.
set -euo pipefail

cd "$(dirname "$0")"

TF=${TF:-terraform}
IMAGE=${IMAGE:-ubuntu:24.04}
NET=tovpn-it
SERVER_IP=172.30.99.10

cleanup() {
  docker rm -f tovpn-server tovpn-client >/dev/null 2>&1 || true
  docker network rm "$NET" >/dev/null 2>&1 || true
}
# Set KEEP=1 to leave the containers running for debugging.
[ -n "${KEEP:-}" ] || trap cleanup EXIT
cleanup

rm -rf .out && mkdir -p .out
"$TF" init -input=false -no-color >/dev/null
"$TF" apply -input=false -auto-approve -no-color -var "server_address=$SERVER_IP" >/dev/null
"$TF" output -raw user_data >.out/user_data.yaml

docker network create --subnet 172.30.99.0/24 "$NET" >/dev/null

docker run -d --name tovpn-server --network "$NET" --ip "$SERVER_IP" \
  --cap-add NET_ADMIN --device /dev/net/tun --sysctl net.ipv4.ip_forward=1 \
  -v "$PWD:/work:ro" "$IMAGE" sh /work/server.sh >/dev/null

echo "Waiting for server ..."
for _ in $(seq 1 180); do
  if docker logs tovpn-server 2>&1 | grep -q "Initialization Sequence Completed"; then
    break
  fi
  if ! docker ps -q --filter name=tovpn-server | grep -q .; then
    docker logs tovpn-server
    echo "server container exited" >&2
    exit 1
  fi
  sleep 1
done
docker logs tovpn-server 2>&1 | grep -q "Initialization Sequence Completed"

echo "Connecting client alice ..."
docker run --rm --name tovpn-client --network "$NET" \
  --cap-add NET_ADMIN --device /dev/net/tun \
  -v "$PWD:/work:ro" "$IMAGE" sh /work/client.sh /work/.out/alice.ovpn

echo "Checking that a client without a ccd entry is rejected ..."
docker exec tovpn-server rm /etc/openvpn/server/ccd/bob
if docker run --rm --name tovpn-client --network "$NET" \
  --cap-add NET_ADMIN --device /dev/net/tun \
  -v "$PWD:/work:ro" "$IMAGE" sh /work/client.sh /work/.out/bob.ovpn >/dev/null 2>&1; then
  echo "bob connected even though ccd/bob was removed" >&2
  exit 1
fi
docker logs tovpn-server 2>&1 | grep "client-config-dir authentication failed for common name 'bob'" | tail -1

echo "PASS"
