#!/bin/bash

# Kubernetes Master Node Initialization Script
# This script initializes the Kubernetes cluster on the master node, sets up the kubeconfig file for kubectl,
# and configures Calico as the CNI (Container Network Interface) plugin.

set -e

# Step 1: Initialize the Kubernetes cluster on the master node
# Pull the required container images for kubeadm
echo "Pulling Kubernetes container images..."
sudo kubeadm config images pull

# Initialize the Kubernetes cluster with a specific pod network CIDR
# Replace the pod-network-cidr with the appropriate value for your network setup
echo "Initializing the Kubernetes cluster..."
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

# Step 2: Configure kubeconfig for kubectl
# This step ensures that kubectl is set up to interact with the Kubernetes cluster
echo "Setting up kubeconfig for kubectl..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Step 3: Install Calico for networking
# Calico is a popular networking and network policy provider for Kubernetes
echo "Installing Calico CNI..."
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.1/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.1/manifests/custom-resources.yaml

echo "Kubernetes master node setup completed successfully."
