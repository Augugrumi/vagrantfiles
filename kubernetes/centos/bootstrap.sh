#!/bin/bash

. <(curl -s https://raw.githubusercontent.com/Polpetta/minibashlib/master/minibashlib.sh)

function main () {

    mb_load "systemop"
    mb_load "logging"

    msg info "Disabling SELinux"
    sudo setenforce 0
    sudo sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

    msg info "Enabling br_netfilter"
    sudo modprobe br_netfilter
    sudo sh -c 'echo "1" > /proc/sys/net/bridge/bridge-nf-call-iptables'

    msg info "Switching off swap"
    sudo swapoff -a
    sudo sed -i '/swap/d' /etc/fstab

    msg info "Updating the system"
    update
    
    sudo sh -c 'echo -e "rbd\nip_vs\nip_vs_rr\nip_vs_wrr\nip_vs_sh" >  /etc/modules-load.d/ip_vs.conf'
    sudo sh -c 'echo -e "dm_snapshot\ndm_mirror\ndm_thin_pool" >  /etc/modules-load.d/gluster.conf'

    msg info "Installing yum-utils"
    install yum-utils

    msg info "Adding docker and kubernetes to machine repos..."
    #sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    
    echo -e '[kubernetes]\nname=Kubernetes\nbaseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg' | sudo tee /etc/yum.repos.d/kubernetes.repo

    msg info "Installing docker and kubernetes"
    install docker device-mapper-persistent-data lvm2 yum-plugin-versionlock kubelet kubectl kubeadm git nano

    msg info "Locking updates for kubernetes and docker components"
    sudo yum versionlock docker
    msg info "Setting up autostart"
    sudo systemctl enable docker && sudo systemctl start docker
    sudo systemctl start kubelet && sudo systemctl enable kubelet
    
}

main
