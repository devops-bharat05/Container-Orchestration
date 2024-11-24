#!/bin/bash

# Function to check the status of the cluster creation
wait_for_cluster_creation() {
  local cluster_name=$1
  echo "Waiting for the EKS cluster '$cluster_name' to be ACTIVE..."
  while true; do
    STATUS=$(eksctl get cluster --name "$cluster_name" --region "$REGION" --output json | jq -r '.[0].Status')
    if [[ "$STATUS" == "ACTIVE" ]]; then
      echo "EKS cluster '$cluster_name' is ACTIVE."
      break
    else
      echo "Cluster status: $STATUS. Retrying in 30 seconds..."
      sleep 30
    fi
  done
}

# Variables
CLUSTER_NAME="mern-cluster02"
REGION="us-west-2"
NODE_GROUP_NAME="standard-workers"
NODE_TYPE="t2.medium"
NODE_COUNT=3
K8S_VERSION="1.31"

echo "Creating EKS Cluster..."
echo "......................................................"
eksctl create cluster \
  --name "$CLUSTER_NAME" \
  --region "$REGION" \
  --nodegroup-name "$NODE_GROUP_NAME" \
  --node-type "$NODE_TYPE" \
  --nodes "$NODE_COUNT" \
  --version "$K8S_VERSION" \
  --upgradePolicy Standard

if [[ $? -ne 0 ]]; then
  echo "Error: Failed to create the EKS cluster."
  exit 1
fi

# Wait for cluster to be ACTIVE
wait_for_cluster_creation "$CLUSTER_NAME"

echo "Setting up NGINX Ingress Controller..."
echo "......................................................"

# Install NGINX Ingress Controller using Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace

echo "......................................................"
echo "Verifying the installation..."
kubectl get all -n ingress-nginx
