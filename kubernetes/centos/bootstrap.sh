#!/usr/bin/env bash

yum update -y

yum install -y docker
systemctl enable docker && systemctl start docker

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
setenforce 0
yum install -y kubelet-1.9.9-0 kubeadm-1.9.9-0 kubectl1.9.9-0
systemctl enable kubelet && systemctl start kubelet

## For Kube-router, see https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#pod-network
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

swapoff -a
sed -i '/swap/d' /etc/fstab

setenforce 0
sed -i '/SELINUX=enforcing/c\SELINUX=disabled' /etc/selinux/config

#!/bin/bash

function check () {
    if [ "$1" -ne 0 ]
    then
        msg err "$2"
        exit 1
    fi
}

function set_dbg () {
    if [ "$1" = "true" ]
    then
        set -x
    else
        set +x
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

function install () {
    sudo yum install -y $1
}

function main () {
    sudo setenforce 0
    sudo sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
    
    sudo modprobe br_netfilter
    sudo sh -c 'echo "1" > /proc/sys/net/bridge/bridge-nf-call-iptables'
    
    sudo swapoff -a
    sudo sed -i '/swap/d' /etc/fstab
    
    install "yum-utils device-mapper-persistent-data lvm2"
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    
    echo -e '[kubernetes]\nname=Kubernetes\nbaseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg\nhttps://packages.cloud.google.com/yum/doc/rpm-package-key.gpg' | sudo tee /etc/yum.repos.d/kubernetes.repo
    
    install "docker-ce yum-plugin-versionlock kubelet-1.9.9-0 kubeadm-1.9.9-0 kubectl1.9.9-0"
    systemctl enable docker && systemctl start docker
    sudo yum versionlock kubelet kubeadm kubectl docker
    
    
}

main
