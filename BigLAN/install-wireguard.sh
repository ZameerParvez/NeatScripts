#! /bin/bash

useage_message="[Example]
./install-wireguard.sh --setup <piVersion> <config-file>
./install-wireguard.sh --change-config <config-file>

To run the script you first need to get a config file from ther server maintainer
This script must be run as root
This script will congfigure the firewall for wireguard


[Required]
-s      --setup         Sets up your pi version with the given config
                        If your pi is version zero, zero w, 1 or 2,
                        then the pi version flag should be set to 0
                        If your pi is version 3 or greater, then set the pi version flag to 1
                        Use the config file given to you by the 
                        maintiner of the server you want to connect to

        --start         Start wireguard
        --stop          Stop wireguard
        --change-config
-h      --help          For this help message
"

current_dir="$(pwd)"
wireguard_dir="/etc/wireguard"
client_config="$wireguard_dir/wg0.conf"

setup=0
piVersion=""
config=""

change_config=0
start=0
stop=0

# makes it run as root
[ "$UID" -eq 0 ] || exec sudo "$0" "$@"

if [ $# -eq 0 ]
then
    echo "No arguments were given"
    echo "$useage_message"
    exit
fi

while [ ! $# -eq 0 ] && [ ! $change_config -eq 1 ] && [ ! $setup -eq 1 ]
do
    case "$1" in
        "-s" | "--setup")
            shift
            setup=1
            piVersion=$1
            shift
            config=$1
            ;;
        "--start")
            shift
            start=1
            ;;
        "--stop")
            shift
            stop=1
            ;;
        "--change-config")
            shift
            change_config=1
            config=$1
            shift
            ;;
        "-h" | "--help")
            echo "$useage_message"
            exit
            ;;
        *)
            echo "\"$1\" is not a valid flag"
            echo "$useage_message"
            exit
            ;;
            
    esac
done

# should happen when installing new 
if [ -e "$client_config" ] && [ ! $change_config -eq 1 ]
then
    echo "A wireguard installation already exists, use --change-config <config> if you want to change your configurations"
    echo "$useage_message"
    exit
fi

if [ $setup -eq 1 ] && [ ! -e "/etc/wireguard/setupcomplete" ]
then
    if [ "$piVersion" == "" ] || [ "$config" == "" ]
    then
        echo "The pi version and config file are required parameters"
        echo "$useage_message"
        exit
    fi
    
    echo "Installing wireguard"

    if [ "$piVersion" -eq 0 ]
    then
        # installs wireguard on older pis
        apt-get update
        apt-get install -y raspberrypi-kernel-headers libelf-dev libmnl-dev build-essential git
        # git clone https://git.zx2c4.com/WireGuard
        # cd "WireGuard/src/"
        # make
        # make install
        # apt install raspberrypi-kernel-headers libelf-dev libmnl-dev build-essential git
        # this one works, the one above doesn't
        git clone https://git.zx2c4.com/wireguard-linux-compat
        git clone https://git.zx2c4.com/wireguard-tools

        make -C wireguard-linux-compat/src -j"$(nproc)"
        sudo make -C wireguard-linux-compat/src install

        make -C wireguard-tools/src -j"$(nproc)"
        sudo make -C wireguard-tools/src install
    else
        # installs wireguard on newer pis
        echo "deb http://deb.debian.org/debian/ unstable main" | sudo tee --append /etc/apt/sources.list
        apt-key adv --keyserver   keyserver.ubuntu.com --recv-keys 04EE7237B7D453EC
        apt-key adv --keyserver   keyserver.ubuntu.com --recv-keys 648ACFD622F3D138
        sh -c 'printf "Package: *\nPin: release a=unstable\nPin-Priority: 90\n" > /etc/apt/preferences.d/limit-unstable'
        apt-get update
        apt install -y wireguard
    fi

    echo "Coppying config and setting firwall rules"
    
    # This might not work if the folder doesn't exist yet
    cd "$current_dir"
    if [ ! -d "$wireguard_dir" ]; 
    then
        mkdir "$wireguard_dir"
    fi
    cp "$config" "$client_config"
    port="$(cat "$config" | grep -i "ListenPort" | cut -f2 -d "=" | xargs echo -n)"
    # sets up firewall stuff
    apt-get install -y ufw
    ufw allow 22/tcp
    ufw allow "$port/udp"
    ufw enable

    # starts up wireguard and sets it to start on boot
    wg-quick up wg0
    systemctl enable wg-quick@wg0

    apt-get upgrade -y

    echo >> "/etc/wireguard/setupcomplete"
    
    echo "Please reboot"

    exit
fi


if [ $start -eq 1 ]
then
    wg-quick up wg0
fi

if [ $stop -eq 1 ]
then
    wg-quick down wg0
fi


if [ $change_config -eq 1 ]
then
    wg-quick down wg0
    # change the config
    port="$(cat "$config" | grep -i "ListenPort" | cut -f2 -d "=" | xargs echo -n)"
    ufw allow "$port/udp"
    cp "$config" "$client_config"
    wg-quick up wg0
    exit
fi


exit