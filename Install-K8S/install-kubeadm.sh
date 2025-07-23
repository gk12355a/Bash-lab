#!/bin/bash
# Script cài đặt Kubernetes và CRI-O trên Ubuntu 22.04

# Cập nhật hệ thống
sudo apt update && sudo apt upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl gpg vim git wget

# Tắt swap
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a
sudo mount -a
free -h

# Cấu hình kernel modules
sudo modprobe overlay
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

# Cài đặt khóa và repo Kubernetes
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Cài đặt Kubernetes
sudo apt update -y
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
kubectl version --client && kubeadm version

# Cài đặt khóa và repo CRI-O
OS="xUbuntu_22.04"
VERSION="1.28"
echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list
curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key | sudo apt-key add -
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key add -

# Cài đặt CRI-O
sudo apt update -y
sudo apt install -y cri-o cri-o-runc

# Cấu hình CRI-O network
sudo sed -i 's/10.85.0.0/172.24.0.0/g' /etc/cni/net.d/100-crio-bridge.conflist
sudo systemctl daemon-reload
sudo systemctl restart crio
sudo systemctl enable crio
sudo systemctl status crio

# Kích hoạt kubelet
sudo systemctl enable kubelet
sudo kubeadm config images pull --cri-socket unix:///var/run/crio/crio.sock