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
