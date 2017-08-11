#!/bin/bash -x

echo "Starting Build Process"

echo "Fully update ..."

apt-get update && apt-get -y dist-upgrade

echo "Install packages we need ..."

apt-get -y install openvpn easy-rsa fail2ban

echo "Enable and configure firewall ..."

ufw enable
ufw default allow outgoing
ufw allow ssh
ufw allow 1194/udp

echo "# START OPENVPN RULES
# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0]
# Allow traffic from OpenVPN client to eth0
-A POSTROUTING -s 192.168.51.0/24 -o eth0 -j MASQUERADE
COMMIT
# END OPENVPN RULES

$(cat /etc/ufw/before.rules)" > /etc/ufw/before.rules

sed -i.bak s/DEFAULT_FORWARD_POLICY=\"DROP\"/DEFAULT_FORWARD_POLICY=\"ACCEPT\"/g /etc/default/ufw

ufw reload

echo "Enable IP forwarding ..."

echo "net/ipv4/ip_forward=1" >> /etc/ufw/sysctl.conf
sysctl -w net.ipv4.ip_forward=1

echo "Configuring OpenVPN..."

cat > /etc/openvpn/server.conf <<EOF
port 1194
proto udp
dev tun
tls-server
tls-auth ta.key 0
ca ca.crt
cert server.crt
key server.key
dh dh2048.pem
cipher AES-256-CBC
keysize 256
server 192.168.51.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
duplicate-cn
keepalive 10 120
comp-lzo
max-clients 5
user nobody
group nogroup
persist-key
persist-tun
status /var/log/openvpn-status.log
log-append /var/log/openvpn.log
verb 3
EOF

echo "Creating certs ..."

make-cadir /etc/openvpn/easy-rsa/

cat >>/etc/openvpn/easy-rsa/vars <<EOF
${cert_details}
export KEY_NAME="${client_config_name}"
EOF

pushd /etc/openvpn/easy-rsa/
chown -R root:sudo .
sudo chmod g+w .
source ./vars
./clean-all
./build-dh
./pkitool --initca
./pkitool --server server
./pkitool client
cd /etc/openvpn/easy-rsa/keys/
openvpn --genkey --secret ta.key
mv server.crt server.key dh2048.pem ta.key /etc/openvpn/
cp ca.crt /etc/openvpn/
popd

echo "Starting and enabling OpenVPN ..."

service openvpn start
update-rc.d openvpn enable

echo "Creating client file ..."

cat > /etc/openvpn/client.ovpn <<EOF
client
dev tun
proto udp
remote $(curl http://169.254.169.254/latest/meta-data/public-ipv4) 1194
resolv-retry infinite
keepalive 10 120
nobind
user nobody
group nogroup
cipher AES-256-CBC
keysize 256
persist-key
persist-tun
ns-cert-type server
comp-lzo
verb 3
key-direction 1
<ca>
$(cat /etc/openvpn/ca.crt)
</ca>
<cert>
$(cat /etc/openvpn/easy-rsa/keys/client.crt)
</cert>
<key>
$(cat /etc/openvpn/easy-rsa/keys/client.key)
</key>
<tls-auth>
$(cat /etc/openvpn/ta.key)
</tls-auth>
EOF

chmod 444 /etc/openvpn/client.ovpn

echo "DONE!"
