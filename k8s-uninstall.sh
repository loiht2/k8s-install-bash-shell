#!/bin/bash

function print_green {
    echo -e "\e[32m$1\e[0m"
}

print_green "Uninstall K8s by kubeadm"
print_green "Stop Kubelet and Containerd"
sudo systemctl stop kubelet
sudo systemctl stop containerd

print_green "Reset container runtime by kubeadm"
sudo kubeadm reset --cri-socket=unix:///var/run/containerd/containerd.sock

print_green "Deleting all configurations ..."
sudo rm -rf /etc/cni/net.d
sudo rm -rf $HOME/.kube/*
sudo rm -rf /var/lib/etcd
sudo rm -rf /var/lib/kubelet/*
sudo rm -rf /etc/kubernetes
