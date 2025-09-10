#!/bin/bash

# Exit on error
set -e

# Function: print green text
function print_green {
    echo -e "\e[32m$1\e[0m"
}

# 1. System update and install required packages
print_green "System Upgrade and Install Required Packages..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gpg apt-transport-https
print_green "Packages installed successfully."

# 2. Configure Kubernetes
print_green "Configuring Kubernetes..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system
print_green "Kubernetes configuration applied."

# 3. Install Docker
print_green "Docker Install..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
print_green "Docker installed successfully."

# 4. Install Kubernetes
print_green "Kubernetes Install..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
print_green "Kubernetes repository added."

# 5. Install kubeadm, kubelet, kubectl
print_green "Kubeadm, Kubelet, Kubectl Install..."
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl --allow-change-held-packages
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet
print_green "Kubeadm, Kubelet, Kubectl installed successfully."

# 6. CGroup Configuration
print_green "Cgroup Configuring..."
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
print_green "CGroup configuration complete."

# 7. Disable swap
print_green "Swap off Set..."
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a
print_green "Swap disabled."

print_green "Kubernetes setup completed successfully! Please restart shell."
