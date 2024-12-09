#!/bin/bash

# Function to create roles
create_roles() {
  local cluster_name=$1
  local cluster_role_name="${cluster_name}-cluster-role"
  local node_role_name="${cluster_name}-node-role"

  # Trust policy JSON files
  local cluster_trust_policy="eks-cluster-trust-policy.json"
  local node_trust_policy="eks-node-trust-policy.json"

  # Create trust policy files
  cat <<EOT > $cluster_trust_policy
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOT

  cat <<EOT > $node_trust_policy
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOT

  echo "Creating IAM role for EKS cluster..."
  aws iam create-role --role-name $cluster_role_name --assume-role-policy-document file://$cluster_trust_policy
  aws iam attach-role-policy --role-name $cluster_role_name --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

  echo "Creating IAM role for EKS node group..."
  aws iam create-role --role-name $node_role_name --assume-role-policy-document file://$node_trust_policy
  aws iam attach-role-policy --role-name $node_role_name --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
  aws iam attach-role-policy --role-name $node_role_name --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
  aws iam attach-role-policy --role-name $node_role_name --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy

  # Cleanup local policy files
  rm -f $cluster_trust_policy $node_trust_policy

  echo "IAM roles for EKS cluster and node group have been created successfully."
}

# Function to delete roles
delete_roles() {
  local cluster_name=$1
  local cluster_role_name="${cluster_name}-cluster-role"
  local node_role_name="${cluster_name}-node-role"

  echo "Detaching and deleting IAM role for EKS cluster..."
  aws iam detach-role-policy --role-name $cluster_role_name --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
  aws iam delete-role --role-name $cluster_role_name

  echo "Detaching and deleting IAM role for EKS node group..."
  aws iam detach-role-policy --role-name $node_role_name --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
  aws iam detach-role-policy --role-name $node_role_name --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
  aws iam detach-role-policy --role-name $node_role_name --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
  aws iam delete-role --role-name $node_role_name

  echo "IAM roles for EKS cluster and node group have been deleted successfully."
}

# Prompt for cluster name and action
read -p "Enter the cluster name: " CLUSTER_NAME
echo "Choose an action:"
echo "1. Create IAM Roles"
echo "2. Delete IAM Roles"
read -p "Enter your choice (1 or 2): " CHOICE

case $CHOICE in
  1)
    create_roles $CLUSTER_NAME
    ;;
  2)
    delete_roles $CLUSTER_NAME
    ;;
  *)
    echo "Invalid choice. Please select 1 or 2."
    ;;
esac
