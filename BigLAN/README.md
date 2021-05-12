# WireGuard VPN with Raspberry Pi as Access Point with PiHole

## Introduction
This project was intended to to make a VPN which allows people on different networks to play multiplayer LAN games.
**However, I think wireguard does not support multicasting, so I decided to stop working on it because games usually discover other clients on the same network by broadcasting messages**. It uses a server to act as the VPN server, and raspberry pis as vpn clients and access points, so that the devices connected the pi access points don't need to support VPN software. I will also involve setting up pi hole, which could be used to resolve dns queries by your home's main router too.

The project contains a few scripts, which all have help messages detailing how they should be used. (there are some more options that can be configured, detailed in the help message, which aren't discussed here)

Another intention of this guide was that it was usable by less technical people (without someone familiar with software being physically present, because of social distancing or being in another city)
The client setup can be completed mostly offline, by giving the person you are setting this up for an sd card with raspbian and wireguard pre installed, and talking through some of the physical setup of the pi. Or by running by having the person setup the pi themselves and continuing the setup remotely, once the client pi is connected to the VPN.

**NOTE: The access point script is unreliable, and not well tested, but many guides to setting it up already exist, which may be helpful**

## Client Setup
## What you will need
- A VPS or some other server to use as the VPN server
- A raspberry pi to act as an access point to the vpn
  - A raspberry pi with Wi-Fi and an Ethernet port is recommended
  - if the pi does not have wireless capabilities a wireless dongle might work
- An Ethernet cable
- A router capable of setting static IPs
- At least a 4GB micro sd

### Setting up a Pi

1. Download and write rasbpian lite to an sd card, there are instructions for this <a href="https://www.raspberrypi.org/downloads/">here</a>

2. Place a file named "SSH" into the root of the boot partition of the sd. More info <a href="https://www.raspberrypi.org/documentation/remote-access/ssh/">here</a>
   - This is so that the raspberry pi can be accessed over LAN

3. Turn on the raspberry pi and connect it with an Ethernet cable to the router
    - Your router might have settings in it which allow you to set and reserve an IP for specific devices 
    - If you don't know the pi's IP you can use nmap to scan the local network with
    ```
    nmap -sn 192.168.1.0/24
    ```

4. Now you can SSH into the pi with
    ```
    ssh pi@<IP>
    ```
    - the default password is
    ```
    raspberry
    ```
    - **If you have already set up your pi another way before with another user, then you would use**
    ```
    ssh <username>@<IP>
    ```
    - You can also set up the pi to use <a href="https://www.raspberrypi.org/documentation/remote-access/ssh/passwordless.md">SSH with keys</a> instead, but it isn't necessary for this tutorial

5. Reset the password as something else by typing this, and then following the prompts
    ```
    passwd
    ```

### Setting up WireGuard on a raspberry pi

1. In one terminal SSH into your raspberry pi, and have another terminal ready to use for later
    - Make sure it has already been set up and has an internet connection

2. Get the install-wireguard.sh script and the config file from the server maintainer

3. From your main OS's terminal, copy the files to your raspberry pi
    - The following command can be used to copy a file to your pi over sftp
    ```
    scp <file-you-want-to-copy> pi@<local-IP>:/home/pi
    ```

4. Next run the install script
    - When using the script for the first time, it will need to install wireguard and ufw (firewall software), which may take some time
    - **There are a few times during the install where it will ask you to type "y"**
    - On the first install you should run this
    ```
    sudo ./install-wireguard.sh --setup <PI-Version-hint> <config-file-path>
    ```
    - **The pi version hint should be 0 if you have any of the following pi versions: pi 2, 1, 0, 0w**
    - **If you have a different pi then the pi version hint should be 1**
    - The config file path should be the path to the config file that the maintainer of the server should have given you
    - A full example of calling this script is
    ```
    sudo ./install-wireguard.sh --setup 0 client-config
    ```

5. Once this is done you should be able to ping or ssh from the server to the client, or vice versa
    - You can do this to check if the connection is working
    ```
    ping <private-ip>
    ```

**At this point the server maintainer should be able to continue the configuration of pihole and the access point software by remotely connecting to the raspberry pi through the vpn.**

### Installing Pi Hole

Pi hole is a DNS resolver that will also block ads and comes with some logging tools too. If you want to you can also configure your router to use this as it's DNS so that all of your home devices have ads blocked.

The "install-pihole.sh" script has automated most of the setup, and can be run with
```
sudo ./install-pihole.sh
```

The pihole admin page should then be accessible by navigating to the pis ip address in your browser

### Making the Pi an access point

The "install-access-point.sh" script can be used to install hostapd on the pi.
It is currently unreliable, so setting up hostapd may be done better another way.

## Server Setup
### Setting up WireGuard on a server

1. Set up a linux server and <a href="https://www.wireguard.com/install/">install wireguard</a>

2. Clone this repo to get the scripts

3. Run ./manage-server.sh --setup, which will configure wireguard with the defaults of the script (alternatively configure it how you want to by reading the script's help message)

4. When using the script to add clients, a client config will be placed in /etc/wireguard/, with the client's private ip as it's name
    ```
    ./manage-server.sh -a 10.66.66.2
    ```
   - Clients can also be removed
    ```
    ./manage-server.sh -r 10.66.66.2
    ```
5. Send the file to the client so that they have an already prepared config file, which can be used by the client side "install-wireguard" script

## Some Tips
- you can use "sudo wg" to show the state of registered wireguard peers, which is useful to see whether packets are being sent
- wireguard can be started and stopped with "wg-quick up wg0" and "wg-quick down wg0", if the wireguard interface is wg0
