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
    sudo apt-get update -qq && \
    sudo apt-get install -y $1
}

function main () {
    install "apt-transport-https docker.io"
    check $? "Failed to install docker"
    msg info "Docker installed successfully"

    sudo systemctl enable docker
    sudo systemctl start docker
    check $? "Failed to start docker"

    sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
    sudo bash -c "echo deb http://apt.kubernetes.io/ kubernetes-xenial main > /etc/apt/sources.list.d/kubernetes.list"

    install "kubelet kubeadm kubectl kubernetes-cni"
    check $? "Failed to install kubernetes"
    msg info "Kubernetes installed successfully"
}

main
