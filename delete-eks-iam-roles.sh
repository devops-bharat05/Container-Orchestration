#!/bin/bash

# Set the cluster name as a variable
CLUSTER_NAME="my-eks-cluster"

# IAM role names
CLUSTER_ROLE_NAME="${CLUSTER_NAME}-cluster-role"
NODE_ROLE_NAME="${CLUSTER_NAME}-node-role"

# Policies attached to the cluster role
CLUSTER_POLICY_ARN="arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

# Policies attached to the node role
NODE_POLICIES=(
  "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
)

# Function to detach policies and delete a role
delete_role() {
  local role_name=$1
  shift
  local policies=("$@")

  echo "Detaching policies from $role_name..."
  for policy_arn in "${policies[@]}"; do
    aws iam detach-role-policy --role-name $role_name --policy-arn $policy_arn
  done

  echo "Deleting role $role_name..."
  aws iam delete-role --role-name $role_name
}

# Delete the cluster role
echo "Deleting IAM role for EKS cluster..."
delete_role $CLUSTER_ROLE_NAME $CLUSTER_POLICY_ARN

# Delete the node role
echo "Deleting IAM role for EKS node group..."
delete_role $NODE_ROLE_NAME "${NODE_POLICIES[@]}"

echo "IAM roles for EKS cluster and node group have been deleted successfully."
