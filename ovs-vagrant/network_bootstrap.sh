#!/bin/bash

function msg() {
    echo -e "==> $1"
}

function check() {
    if [ $1 -eq 0 ]
    then
        msg "\e[32m$2\e[39m"
    else
        msg "\e[31m$3\e[39m"
        exit 1
    fi
}

msg "Open vSwitch status: $(systemctl status openvswitch | grep 'Active' | cut -f 5- -d' ')"
msg "Docker status: $(systemctl status docker | grep 'Active' | cut -f 5- -d' ')"

msg "Creating ovs bridge..."
sudo ovs-vsctl add-br ovs-br1
check $? "Bridge created" "Failed to create the ovs bridge"
sudo ovs-vsctl show

msg "Configuring the internal IP Address..."
sudo ifconfig ovs-br1 192.168.0.1 netmask 255.255.0.0 up
check $? "Interal IP added successfully" "Failed to create internal ip"
ifconfig ovs-br1

#~ msg "Building docker image for pinging the other host..."
#~ cd /vagrant/docker/ping/
#~ docker build -t polpetta/ping:latest .
#~ check $? "Docker image built successfully" "Failed to create docker image"
#~ cd -

msg "Launching containers..."
docker run -d --name=container1 --net=none polpetta/ping
check $? "Conatiner 1 launched" "Failed to launch container 1"
docker run -d --name=container2 --net=none polpetta/ping
check $? "Container 2 launched" "Failed to launch container 2"

msg "Setting ip tables"
export pubintf=eth0
export privateintf=ovs-br1
sudo iptables -t nat -A POSTROUTING -o $pubintf -j MASQUERADE
sudo iptables -A FORWARD -i $privateintf -j ACCEPT
sudo iptables -A FORWARD -i $privateintf -o $pubintf -m state --state RELATED,ESTABLISHED -j ACCEPT
check $? "Iptables correctly set" "Failed to set iptables"
msg "Iptables config"
sudo iptables -S

msg "Setting ovs bridges on docker containers..."
sudo ovs-docker add-port ovs-br1 eth0 container1 --ipaddress=192.168.1.1/16 --gateway=192.168.0.1
sudo ovs-docker add-port ovs-br1 eth0 container2 --ipaddress=192.168.1.2/16 --gateway=192.168.0.1
if [ $(sudo ovs-vsctl list-ports ovs-br1 | wc -l) -eq 2 ]
then
    msg "\e[32mPorts set correctly\e[39m"
else
    msg "\e[31mFailed to set ports\e[39m"
    exit 1
fi

msg "Configuration done"
msg "Pinging container2 from container1"
docker exec container1 ping -c 3 192.168.1.2
check $? "Ping done correctly" "Failed to ping container2 from container1"

msg "Flow output:"
sudo ovs-ofctl dump-flows ovs-br1
