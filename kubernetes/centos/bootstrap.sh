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

    msg info "Installing yum-utils"
    install yum-utils

    msg info "Adding docker and kubernetes to machine repos..."
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    
    echo -e '[kubernetes]\nname=Kubernetes\nbaseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg' | sudo tee /etc/yum.repos.d/kubernetes.repo

    msg info "Installing docker and kubernetes"
    install docker-ce device-mapper-persistent-data lvm2 yum-plugin-versionlock kubelet-1.9.9-0 kubectl-1.9.9-0 kubeadm-1.9.9-0

    msg info "Setting up autostart"
    sudo yum versionlock kubelet kubeadm kubectl docker
    sudo systemctl enable docker && sudo systemctl start docker
    
}

main
