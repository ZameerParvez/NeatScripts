#! /bin/bash
# These instructions work but ufw needs to be disabled or reconfigured a bit to make it connect to the internet
# /etc/default/ufw change deafault forwarding to accept
# /etc/ufw/sysctl.conf add the same ipv4 and 6 things i do elsewhere

useage_message="[Example]
./install-access-point.sh --ssid <name> --password <password> --channel <channel> -cc <country_code>

To run the script you first need to get a config file from ther server maintainer
This script must be run as root
This script will congfigure the firewall for wireguard


[Required]
-s      --ssid          Set the SSID that the pi should have
-p      --password      Set the password for the access point
-c      --channel       Set the channel that the access point should be working on
-cc     --country_code  Used to configure the wireless settings that are available for the given country
-h      --help          For this help message
"

if [ $# -eq 0 ]
then
    echo "No arguments were given"
    echo "$useage_message"
    exit
fi

ssid=""
channel="7"
password=""
country_code="GB"

while [ ! $# -eq 0 ]
do
    case "$1" in
        "-s" | "--ssid")
            shift
            ssid="$1"
            shift
            ;;
        "-cc" | "--country_code")
            shift
            country_code="$1"
            shift
            ;;
        "-p" | "--password")
            shift
            password="$1"
            shift
            ;;
        "-c" | "--channel")
            shift
            channel="$1"
            shift
            ;;
        "-h" | "--help")
            echo "$useage_message"
            exit
            ;;
    esac
done

if [ "$ssid" == "" ] || [ "$password" == "" ]
then
    echo "A password and ssid are required"
    echo "$useage_message"
    exit
fi

# dnsmasq would already be downloaded by pihole
sudo apt install -y hostapd

sudo systemctl stop hostapd

# This isn't the actual driver used for the device it is more general
# driver="$(ethtool -i wlan0 | grep "driver" | cut -f2 -d " ")"
driver="nl80211"
# This bit is about giving the DHCP server a static IP on the pi network
echo "interface=wlan0
bridge=wg0
country_code=$country_code
ieee80211d=1
ieee80211n=1
driver=$driver
ssid=$ssid
hw_mode=g
channel=$channel
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$password
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP" >> /etc/hostapd/hostapd.conf

echo "DAEMON_CONF=\"/etc/hostapd/hostapd.conf\"" >> /etc/default/hostapd

sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl start hostapd

echo "net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding = 1" >> "/etc/sysctl.conf"  
sysctl -p

# might need to be wg0
# iptables -t nat -A  POSTROUTING -o eth0 -j MASQUERADE
iptables -t nat -A  POSTROUTING -o wg0 -j MASQUERADE

# enable forwarding by ufw
sudo ufw default allow FORWARD  # either this or change it in that /etc/default/ufw
echo "net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding = 1" >> "/etc/ufw/sysctl.conf"
# I don't know if it is needed but, Add the following to the bit after the headers of /etc/ufw/before.rules

# # nat Table rules
# *nat
# :POSTROUTING ACCEPT [0:0]

# # Forward traffic through eth8.
# -A POSTROUTING -s 192.168.0.0/24 -o wg0 -j MASQUERADE

# # don't delete the 'COMMIT' line or these nat table rules won't be processed
# COMMIT

apt-get install -y iptables-persistent
# if already installed do sudo dpkg-reconfigure iptables-persistent