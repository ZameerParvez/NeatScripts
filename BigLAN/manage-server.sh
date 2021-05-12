#! /bin/bash

# script should require WAN address, port, optional private key (if just setting up again)
# should have an add client feature, which generates keys and configs and appends to the original config and output the required client config
# assumes wireguard is already set up
# should also set up the firewall a bit

useage_message="[Example]
./manage-wireguard-server.sh -s -WIP <WANIP> -p <port> --allowedIPs <allowedIPs-string> -a <client-1-WANIP> <client-2-WANIP> <client-3-WANIP>

This script must be run as root
It will automatically start wireguard and add it as a service. Stopping wireguard does not remove it from systemctl services
It will also install ufw and set some firewall rules which can be seen with \"sudo ufw status\"
NOTE: -a must be the last flag in the argument list, anything after should be a unique WANIP

-h      --help          For this help message
[required for setup]
-s      --setup         Flag to do initial server setup

[optional for setup]
-WIP    --WANIP         Set the WAN IP of the server (default: 10.66.66.1)
-p      --port          Set the listening port (default: 1194)

[required to add clients]
-a      --add-client <WANIP>
-r      --remove-client <WANIP>

[optional to add clients]
        --allowedIPs    Set allowed IPs for the clients configs (default: only ips on WAN 10.66.66.*)

[other]
        --start         Start wireguard
        --stop          Stop wireguard
"

server_config="/etc/wireguard/wg0.conf"

setup=0
WANIP="10.66.66.1"
port="1194"
allowedIPs="$(echo "$WANIP" | cut -f-3 -d ".").0/24,$WANIP/32"
add_clients=0
remove_clients=0

start=0
stop=0

if [ $# -eq 0 ]
then
    echo "No arguments were given"
    echo "$useage_message"
    exit
fi

while [ ! $# -eq 0 ] && [ ! $add_clients -eq 1 ] && [ ! $remove_clients -eq 1 ]
do
    case "$1" in
        "-s" | "--setup")
            shift
            setup=1
            ;;
        "-WIP" | "--WANIP")
            shift
            WANIP=$1
            shift
            ;;
        "-p" | "--port")
            shift
            port=$1
            shift
            ;;
        "--allowedIPs")
            shift
            allowedIPs=$1
            shift
            ;;
        "-a" | "--add-clients")
            shift
            add_clients=1
            ;;
        "-r" | "--remove-clients")
            shift
            remove_clients=1
            ;;
        "--start")
            shift
            start=1
            ;;
        "--stop")
            shift
            stop=1
            ;;
        "-h" | "--help")
            echo "$useage_message"
            exit
            ;;
        *)
            echo "$1 is not a valid flag"
            echo "$useage_message"
            exit
    esac
done

# it might make more sense to make the key generation and config generation happen a server script utility

if [ ! -d "/etc/wireguard" ]
then
    echo "Wireguard might not be installed because \"/etc/wireguard\" does not exist"
    echo "$useage_message"
    exit
fi

# generates keys for wireguard server and initial config if there is none and sets up the firewalls properly
if [ $setup -eq 1 ]
then
    echo "Backing up previous config"
    mv "$server_config" "$server_config.bak"
    mv "/etc/wireguard/pubkey" "/etc/wireguard/pubkey.bak"
    mv "/etc/wireguard/WANIP" "/etc/wireguard/WANIP.bak" 
    mv "/etc/wireguard/port" "/etc/wireguard/port.bak"

    echo "Setting up server's wireguard config"

    server_private_key="$(wg genkey)"
    server_public_key="$(echo -n "$server_private_key" | wg pubkey)"

    {
        echo "[Interface]"
        echo "Address = $WANIP"
        echo "ListenPort = $port"
        echo "PrivateKey = $server_private_key"
        echo "PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE"
        echo "PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE"
        # echo "SaveConfig = true"
    } >> "$server_config"

    echo "$server_public_key" >> "/etc/wireguard/pubkey"
    echo "$WANIP" >> "/etc/wireguard/WANIP"
    echo "$port" >> "/etc/wireguard/port"
    
    echo "Configs saved"

    echo "Setting up firewalls"
    # sets up firewall stuff
    apt-get install -y ufw
    ufw allow 22/tcp
    ufw allow "$port"/udp


    if [ ! -e "/etc/wireguard/initialsetupflag" ]
    then
        echo "initialsetupflag" >> "/etc/wireguard/initialsetupflag"
        echo "Enabling port forwarding"
        echo "net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding = 1" >> "/etc/sysctl.conf"  
        sysctl -p
        
        echo "Enabling wireguard and setting up service"
        systemctl enable wg-quick@wg0
        ufw enable
    fi

    wg-quick up wg0
fi

if [ $start -eq 1 ]
then
    wg-quick up wg0
fi

if [ $stop -eq 1 ]
then
    wg-quick down wg0
fi

# write server WANIP, port and maybe otherthings to file first so that they're easy to reference

if [ $remove_clients -eq 1 ]
then
    if [ $# -eq 0 ]
    then
        echo "You might be missing WAN IPs for the clients you want to remove"
    fi

    while [ ! $# -eq 0 ]
    do
        client_WANIP="$1"
        client_config="/etc/wireguard/$client_WANIP"
        client_public_key="$(cat "$client_config" | grep -i PrivateKey | cut -f3 -d " " | wg pubkey)"
        rm "$client_config"
        wg set wg0 peer "$client_public_key" remove
        
        echo "client with private IP \"$client_WANIP\" has been removed"
        shift
    done

    exit
fi

if [ $add_clients -eq 1 ]
then
    if [ $# -eq 0 ]
    then
        echo "You might be missing WAN IPs for the clients you want to add"
    fi

    server_public_key="$(cat "/etc/wireguard/pubkey")"
    server_WANIP="$(cat "/etc/wireguard/WANIP")"
    server_port="$(cat "/etc/wireguard/port")"
    actual_server_IP="$(hostname -I | cut -f1 -d " ")"

    allowedIPs="$(echo "$server_WANIP" | cut -f-3 -d ".").0/24,$WANIP/32"

    while [ ! $# -eq 0 ]
    do
        # clients configs should be written to files here with there names as the wanips
        # they should also be correctly appended to the server config
        client_WANIP="$1"
        client_config="/etc/wireguard/$client_WANIP"

        if [ ! -e "$client_config" ]
        then
            client_private_key="$(wg genkey)"
            client_public_key="$(echo "$client_private_key" | wg pubkey)"
            
            wg set wg0 peer "$client_public_key" allowed-ips "$client_WANIP/32" persistent-keepalive 60
            wg-quick save wg0

            # set up client config
            {
                echo "[Interface]"
                echo "PrivateKey = $client_private_key"
                echo "Address = $client_WANIP/32"   # not sure if this /24 should be here
                echo "ListenPort = $server_port"    # clients work on the same port as the server
                echo "[Peer]"
                echo "PublicKey = $server_public_key"
                echo "Endpoint = $actual_server_IP:$server_port"
                echo "AllowedIPs = $allowedIPs" 
            } >> "$client_config"

            cat "$client_config"
        else
            echo "A client config for $client_WANIP already exists"
        fi

        shift
    done
    exit
fi

exit