#!/bin/bash

# Variables
CLUSTER_NAME="mern-cluster02"
REGION="us-west-2"
NGINX_NAMESPACE="ingress-nginx"

# Function to delete NGINX Ingress Controller
delete_nginx_ingress() {
  echo "Deleting NGINX Ingress Controller in namespace $NGINX_NAMESPACE..."
  helm uninstall nginx-ingress --namespace "$NGINX_NAMESPACE"
  if [[ $? -eq 0 ]]; then
    echo "Successfully deleted NGINX Ingress Controller."
  else
    echo "Error: Failed to delete NGINX Ingress Controller."
  fi

  echo "Deleting namespace $NGINX_NAMESPACE..."
  kubectl delete namespace "$NGINX_NAMESPACE"
  if [[ $? -eq 0 ]]; then
    echo "Successfully deleted namespace $NGINX_NAMESPACE."
  else
    echo "Error: Failed to delete namespace $NGINX_NAMESPACE or it may not exist."
  fi
}

# Function to delete the EKS cluster
delete_eks_cluster() {
  echo "Deleting EKS Cluster '$CLUSTER_NAME' in region $REGION..."
  eksctl delete cluster --name "$CLUSTER_NAME" --region "$REGION"
  if [[ $? -eq 0 ]]; then
    echo "Successfully deleted EKS cluster '$CLUSTER_NAME'."
  else
    echo "Error: Failed to delete EKS cluster '$CLUSTER_NAME'."
  fi
}

# Confirm deletion
read -p "Are you sure you want to delete the EKS cluster '$CLUSTER_NAME' and NGINX Ingress Controller? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  echo "Aborting deletion process."
  exit 1
fi

# Start deletion process
echo "Starting deletion process..."
delete_nginx_ingress
delete_eks_cluster

echo "Deletion process completed."
