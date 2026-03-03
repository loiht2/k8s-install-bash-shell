#!/bin/bash

# Exit on error
set -e

# Function: print green text
function print_green {
    echo -e "\e[32m$1\e[0m"
}

# Versions
KUBERNETES_VERSION="v1.35"
CRIO_VERSION="v1.35"

# 1. System update and install required packages
print_green "System Upgrade and Install Required Packages..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gpg apt-transport-https software-properties-common
print_green "Packages installed successfully."

# 2. Configure Kubernetes kernel modules + sysctl
print_green "Configuring Kubernetes kernel modules and sysctl..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
print_green "Kubernetes sysctl configuration applied."

# 3. Add repositories (CRI-O + Kubernetes v1.35)
print_green "Adding CRI-O and Kubernetes repositories..."
sudo mkdir -p -m 755 /etc/apt/keyrings

# CRI-O repo (stable v1.35)
curl -fsSL "https://download.opensuse.org/repositories/isv:/cri-o:/stable:/${CRIO_VERSION}/deb/Release.key" \
  | sudo gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://download.opensuse.org/repositories/isv:/cri-o:/stable:/${CRIO_VERSION}/deb/ /" \
  | sudo tee /etc/apt/sources.list.d/cri-o.list > /dev/null

# Kubernetes repo (stable v1.35)
curl -fsSL "https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/Release.key" \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/ /" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

print_green "Repositories added successfully."

# 4. Install CRI-O + kubelet/kubeadm/kubectl
print_green "Installing CRI-O + kubelet/kubeadm/kubectl..."
sudo apt-get update
sudo apt-get install -y cri-o kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Enable/start services
sudo systemctl enable --now crio
sudo systemctl enable --now kubelet

print_green "CRI-O and Kubernetes components installed successfully."

# 5. Disable swap
print_green "Disabling swap..."
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a
print_green "Swap disabled."

# 6. Setup Master Node (using CRI-O socket)
print_green "Initializing control-plane with kubeadm (CRI-O)..."
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --control-plane-endpoint=$(hostname -I | awk '{print $1}') \
  --cri-socket=unix:///var/run/crio/crio.sock

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
print_green "Control-plane initialized."

# 7. Install CNI (Flannel)
print_green "Installing CNI (Flannel)..."
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
print_green "CNI installed successfully."

# 8. Install Bash Completion
print_green "Installing bash-completion..."
sudo apt-get install -y bash-completion
source /usr/share/bash-completion/bash_completion
echo 'source <(kubectl completion bash)' >>~/.bashrc
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -F __start_kubectl k' >>~/.bashrc
print_green "Bash completion installed."

print_green "Kubernetes v1.35 + CRI-O setup completed successfully! Please restart shell."

#(Optional) Allow scheduling on control-plane (single-node cluster)
#kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

#Your Kubernetes control-plane has initialized successfully!
#To start using your cluster, you need to run the following as a regular user:
#  mkdir -p $HOME/.kube
#  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
#  sudo chown $(id -u):$(id -g) $HOME/.kube/config
#Alternatively, if you are the root user, you can run:
#  export KUBECONFIG=/etc/kubernetes/admin.conf
