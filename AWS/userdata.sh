#!/bin/bash -x

INTERFACE=$(route | grep '^default' | grep -o '[^ ]*$')

echo "Starting Build Process"

echo "Reset DNS settings ..."

echo "supersede domain-name-servers 1.1.1.1, 9.9.9.9;" >> /etc/dhcp/dhclient.conf

dhclient -r -v $INTERFACE && rm /var/lib/dhcp/dhclient.* ; dhclient -v $INTERFACE

echo "Adding official OpenVPN Distro ..."

wget -O - https://swupdate.openvpn.net/repos/repo-public.gpg|apt-key add -

echo "deb http://build.openvpn.net/debian/openvpn/stable `lsb_release -cs` main" > /etc/apt/sources.list.d/openvpn.list

echo "Update apt sources ..."
echo "deb http://archive.ubuntu.com/ubuntu/ xenial main restricted
deb http://archive.ubuntu.com/ubuntu/ xenial-updates main restricted
deb http://archive.ubuntu.com/ubuntu/ xenial universe
deb http://archive.ubuntu.com/ubuntu/ xenial-updates universe
deb http://archive.ubuntu.com/ubuntu/ xenial multiverse
deb http://archive.ubuntu.com/ubuntu/ xenial-updates multiverse
deb http://archive.ubuntu.com/ubuntu/ xenial-backports main restricted universe multiverse" > /etc/apt/sources.list.d/ubuntu.list

echo "Fully update ..."

unset UCF_FORCE_CONFFOLD
export UCF_FORCE_CONFFNEW=YES
ucf --purge /boot/grub/menu.lst

export DEBIAN_FRONTEND=noninteractive
apt update
apt -o Dpkg::Options::="--force-confnew" --force-yes -fuy dist-upgrade

echo "Install packages we need ..."

apt -y install openvpn easy-rsa fail2ban unattended-upgrades

echo "Enable and configure firewall ..."

ufw --force enable
ufw default allow outgoing
ufw allow ssh
ufw allow 1194/udp

TMPFILE=$(mktemp)

echo "# START OPENVPN RULES
# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0]
# Allow traffic from OpenVPN client to $INTERFACE
-A POSTROUTING -s 192.168.51.0/24 -o $INTERFACE -j MASQUERADE
COMMIT
# END OPENVPN RULES" | cat - /etc/ufw/before.rules > $TMPFILE

mv -f $TMPFILE /etc/ufw/before.rules

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
tls-crypt ta.key 0
tls-version-min 1.2
ca ca.crt
cert server.crt
key server.key
dh dh2048.pem
topology subnet
server 192.168.51.0 255.255.255.0
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
remote $(curl http://169.254.169.254/latest/meta-data/public-ipv4) 1194
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
