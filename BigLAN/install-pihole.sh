#! /bin/bash

# when configuring the pihole the addresses should be what I want them to be, not default
# e.g. should be something like 192.168.2.0/24, with 192.168.2.1 as the gateway, then the DHCP server needs to be enabled

sudo apt-get install -y ufw

ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 53/tcp
ufw allow 53/udp
ufw allow 67/tcp
ufw allow 67/udp
ufw allow 546:547/udp

echo "nameserver 1.1.1.1" >> "/etc/resolv.conf"

curl -sSL https://install.pi-hole.net | bash

cat "/etc/resolv.conf"

echo "If the installation has failed and there is an error like \"FTL Engine not installed\", then re run the script"
echo "If Pihole is successfully installed, then to reset the pihole password run \"pihole -a -p <Your-Password>\", you can then login at <Raspberry-pi's-local-IP>/admin"