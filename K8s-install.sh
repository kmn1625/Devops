#!/bin/bash

# Kubernetes Setup Script
# This script performs the necessary setup steps to configure a Kubernetes cluster on Ubuntu nodes.
# It includes disabling swap, updating the /etc/hosts file, configuring the IPV4 bridge, installing Docker,
# and setting up Kubernetes components (kubelet, kubeadm, kubectl).

set -e

# Step 1: Disable swap
echo "Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Step 2: Update the /etc/hosts File for Hostname Resolution
echo "Updating /etc/hosts for hostname resolution..."
cat <<EOF | sudo tee -a /etc/hosts
# Add your nodes' IP addresses and hostnames here
10.128.0.24   master-node
10.128.0.24   worker-node
EOF

# Step 3: Set up the IPV4 bridge on all nodes
echo "Setting up IPV4 bridge..."
# Load kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# Configure sysctl parameters
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl parameters without reboot
sudo sysctl --system

# Step 4: Install Docker
echo "Installing Docker..."
sudo apt update
sudo apt install -y docker.io

# Create containerd configuration directory and configure containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/ SystemdCgroup = false/ SystemdCgroup = true/' /etc/containerd/config.toml

# Restart containerd and enable kubelet service
sudo systemctl restart containerd.service

# Step 5: Install kubelet, kubeadm, and kubectl on each node
echo "Installing Kubernetes components (kubelet, kubeadm, kubectl)..."
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Create the keyrings directory if it doesn't exist
sudo mkdir -p -m 755 /etc/apt/keyrings

# Download the Kubernetes package key and set up the repository
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add the Kubernetes apt repository
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update the package list and install the Kubernetes components
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl

# Hold the Kubernetes components to prevent them from being upgraded automatically
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl restart kubelet.service
sudo systemctl enable kubelet.service

# Enable and start kubelet
sudo systemctl enable --now kubelet

echo "Kubernetes setup completed successfully."
