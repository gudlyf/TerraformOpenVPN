#!/bin/bash -x

echo "Starting Build Process"

INTERFACE=$(route | grep '^default' | grep -o '[^ ]*$')

echo "Reset DNS settings ..."

echo "supersede domain-name-servers 1.1.1.1, 9.9.9.9;" >> /etc/dhcp/dhclient.conf

dhclient -r -v $${INTERFACE} && rm /var/lib/dhcp/dhclient.* ; dhclient -v $${INTERFACE}

echo "Adding official OpenVPN Distro ..."

wget -O - https://swupdate.openvpn.net/repos/repo-public.gpg|apt-key add -

echo "deb http://build.openvpn.net/debian/openvpn/stable `lsb_release -cs` main" > /etc/apt/sources.list.d/openvpn-aptrepo.list

echo "Fully update ..."

apt-get update && apt-get -y dist-upgrade

echo "Install packages we need ..."

apt-get -y install openvpn easy-rsa fail2ban

echo "Enable and configure firewall ..."

echo "y" | ufw enable
ufw default allow outgoing
ufw allow ssh
ufw allow 1194/udp

echo "# START OPENVPN RULES
# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0]
# Allow traffic from OpenVPN client to $${INTERFACE}
-A POSTROUTING -s 192.168.53.0/28 -o $${INTERFACE} -j MASQUERADE
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
tls-cipher TLS-ECDHE-RSA-WITH-AES-256-GCM-SHA384
cipher AES-256-CBC
auth SHA512
tls-crypt ta.key
tls-version-min 1.2
ca ca.crt
cert server.crt
key server.key
dh dh2048.pem
topology subnet
server 192.168.53.0 255.255.255.0
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 1.1.1.1"
push "dhcp-option DNS 9.9.9.9"
duplicate-cn
keepalive 10 120
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

echo "Enabling and starting OpenVPN ..."

systemctl enable openvpn.service
systemctl start openvpn.service

echo "Creating client file ..."

cat > /etc/openvpn/client.ovpn <<EOF
client
dev tun
proto udp
remote $(curl -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/publicIpAddress?api-version=2017-08-01&format=text") 1194
resolv-retry infinite
keepalive 10 120
topology subnet
pull
nobind
user nobody
group nogroup
tls-client
tls-cipher TLS-ECDHE-RSA-WITH-AES-256-GCM-SHA384
cipher AES-256-CBC
auth SHA512
persist-key
persist-tun
auth-nocache
remote-cert-tls server
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
<tls-crypt>
$(cat /etc/openvpn/ta.key)
</tls-crypt>
EOF

chmod 444 /etc/openvpn/client.ovpn

echo "DONE!"
