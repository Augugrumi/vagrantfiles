#!/bin/bash

# Author: Davide Polonio <poloniodavide@gmail.com>
# License: GPLv3+

function loadConfig () {
    source bootstrap.conf
    check $? "Failed to load bootstrap.conf!"
}

function check () {
    if [ "$1" -ne 0 ]
    then
        msg err "$2"
        exit 1
    fi
}

function msg () {
    # 3 type of messages:
    # - info
    # - warn
    # - err
    local color=""
    local readonly default="\033[m" #reset
    if [ "$1" = "info" ]
    then
        color="\033[0;32m" #green
    elif [ "$1" = "warn" ]
    then
        color="\033[1;33m" #yellow
    elif [ "$1" = "err" ]
    then
        color="\033[0;31m" #red
    fi

    echo -e "$color==> $2$default"
}

function getUbuntuVersion () {
    echo $(lsb_release -r | cut -f2)
}

function openstackWizard () {
    sudo apt-get update
    sudo apt-get upgrade -y
    sudo apt-get install -y python-systemd
    sudo apt-get autoclean
    sudo apt-get autoremove -y

    cd $HOME
    rm -rf devstack/
    git clone https://git.openstack.org/openstack-dev/devstack -b "$1" --depth=1
    check $? "Failed to clone openstack repo"
    cd devstack

    sudo mkdir /logs
    sudo chown -R "$(whoami)":"$(whoami)" /logs
    mkdir logs

    local readonly ADMIN_PASSWORD="Password1"
    local readonly myIpAddress="$(ip a show $2 | grep inet | head -n1 | cut -d" " -f6 | cut -d"/" -f1)"
    cat <<EOF > local.conf
[[local|localrc]]
############################################################
# Customize the following HOST_IP based on your installation
############################################################
HOST_IP=$myIpAddress

ADMIN_PASSWORD=$ADMIN_PASSWORD
MYSQL_PASSWORD=$ADMIN_PASSWORD
RABBIT_PASSWORD=$ADMIN_PASSWORD
SERVICE_PASSWORD=$ADMIN_PASSWORD
SERVICE_TOKEN=$ADMIN_PASSWORD

############################################################
# Customize the following section based on your installation
############################################################

# Pip
PIP_USE_MIRRORS=False
USE_GET_PIP=1

#OFFLINE=False
#RECLONE=True

# Logging
LOGFILE=$DEST/logs/stack.sh.log
VERBOSE=True
ENABLE_DEBUG_LOG_LEVEL=True
ENABLE_VERBOSE_LOG_LEVEL=True

# Neutron ML2 with OpenVSwitch
Q_PLUGIN=ml2
Q_AGENT=openvswitch

SWIFT_REPLICAS=1
FLOATING_RANGE=$(echo "$myIpAddress" | cut -d"." -f4 --complement).224/27
FLOAT_INTERFACE=$2

# Disable security groups
Q_USE_SECGROUP=False
LIBVIRT_FIREWALL_DRIVER=nova.virt.firewall.NoopFirewallDriver

# Enable heat, networking-sfc, barbican and mistral
enable_plugin heat https://git.openstack.org/openstack/heat stable/queens
enable_plugin networking-sfc git://git.openstack.org/openstack/networking-sfc stable/queens
enable_plugin barbican https://git.openstack.org/openstack/barbican stable/queens
enable_plugin mistral https://git.openstack.org/openstack/mistral stable/queens

# Ceilometer
#CEILOMETER_PIPELINE_INTERVAL=300
enable_plugin ceilometer https://git.openstack.org/openstack/ceilometer stable/queens
enable_plugin aodh https://git.openstack.org/openstack/aodh stable/queens

# Tacker
enable_plugin tacker https://git.openstack.org/openstack/tacker stable/queens

enable_service n-novnc
enable_service n-cauth

disable_service tempest

# Enable Kubernetes and kuryr-kubernetes
#KUBERNETES_VIM=True
#NEUTRON_CREATE_INITIAL_NETWORKS=False
#enable_plugin kuryr-kubernetes https://git.openstack.org/openstack/kuryr-kubernetes stable/queens
#enable_plugin neutron-lbaas git://git.openstack.org/openstack/neutron-lbaas stable/queens
#enable_plugin devstack-plugin-container https://git.openstack.org/openstack/devstack-plugin-container stable/queens

[[post-config|/etc/neutron/dhcp_agent.ini]]
[DEFAULT]
enable_isolated_metadata = True
EOF

    msg info "Launching devstack installation..."
    sleep 3 # Calm before the storm...
    ./stack.sh
    check $? "Something bad happened during devstack installation! I'm sorry :("
    cd -
    cd horizon/ && python manage.py compress && cd -
    check $? "Failed to recreate horizon cache!"
    sudo service apache2 restart
    msg info "Devstack installation complete! Enjoy!"
}

function main () {

    local readonly LAUNCH_USERNAME="$(whoami)"
    local readonly LAUNCH_USERNAME_HOME=$HOME
    local readonly NEW_USERNAME="stack"
    local readonly NEW_USERNAME_HOME="/opt/stack"

    if [ "$(getUbuntuVersion)" != "16.04" ]
    then
        msg err "This script supports only Ubuntu 16.04 and must be runned with a user called ubuntu"
    fi

    if [ $(pwd) != "$HOME" ]
    then
        msg info "Copying the script in the right location"
        cp "$0" "$HOME/$(basename $0)"
        check $? "Failed to copy the script in the right location"
        rm $0
        cd $HOME
        chmod +x "$(basename $0)"
        ./$(basename $0) $@
    fi

    local branch="master"
    local linkinterface=""
    local install=1
    while getopts ":i :b: :l:" opt; do
        case $opt in
            i)
                msg info "Installing Openstack with user $(whoami)..."
		install=0
                ;;
            b)
                msg info "Setting branch to $OPTARG"
                branch="$OPTARG"
                ;;
	    l)
		msg info "Interface link set to $OPTARG"
		linkinterface="$OPTARG"
		;;
            \?)
                msg err "Invalid option: -$OPTARG" >&2
                exit 1
                ;;
            :)
                msg err "Option -$OPTARG requires an argument." >&2
                exit 1
                ;;
        esac
    done

    if [ "$install" -eq 0 ]
    then
	if [ "$linkinterface" != "" ]
	then
	    openstackWizard "$branch" "$linkinterface"
	else
	    msg err "You MUST set a pastebin url for your local config"
	fi
    else
	msg info "Launching installation as $LAUNCH_USERNAME"
        echo "$LAUNCH_USERNAME ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$LAUNCH_USERNAME
        sudo useradd -s /bin/bash -d $NEW_USERNAME_HOME -m $NEW_USERNAME
        echo "$NEW_USERNAME ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$NEW_USERNAME
	sudo -p "Restarting as stack, please type your credentials\n" su -c "$LAUNCH_USERNAME_HOME/bootstrap.sh -b $branch -l $linkinterface -i" $NEW_USERNAME
    fi
}

main $@
