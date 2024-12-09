#!/bin/bash

# Function to create trust policy files
create_trust_policy_files() {
  local cluster_trust_policy=$1
  local node_trust_policy=$2

  echo "Creating trust policy files..."

  # EKS Cluster trust policy
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

  # Node group trust policy
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
}

# Function to create IAM roles and attach policies
create_roles() {
  local cluster_name=$1
  local cluster_role_name="${cluster_name}-cluster-role"
  local node_role_name="${cluster_name}-node-role"

  # Temporary trust policy files
  local cluster_trust_policy="${cluster_name}_eks_cluster_trust_policy.json"
  local node_trust_policy="${cluster_name}_eks_node_trust_policy.json"

  # Create trust policy files
  create_trust_policy_files $cluster_trust_policy $node_trust_policy

  echo "Creating IAM role for EKS cluster..."
  aws iam create-role --role-name $cluster_role_name --assume-role-policy-document file://$cluster_trust_policy
  aws iam attach-role-policy --role-name $cluster_role_name --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

  echo "Creating IAM role for EKS node group..."
  aws iam create-role --role-name $node_role_name --assume-role-policy-document file://$node_trust_policy
  aws iam attach-role-policy --role-name $node_role_name --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
  aws iam attach-role-policy --role-name $node_role_name --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
  aws iam attach-role-policy --role-name $node_role_name --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy

  # Fetch and display ARNs of created roles
  echo "Fetching ARNs of created roles..."
  cluster_role_arn=$(aws iam get-role --role-name $cluster_role_name --query "Role.Arn" --output text)
  node_role_arn=$(aws iam get-role --role-name $node_role_name --query "Role.Arn" --output text)

  echo "EKS Cluster Role ARN: $cluster_role_arn"
  echo "EKS Node Role ARN: $node_role_arn"

  echo "Trust policy files used for role creation:"
  echo "Cluster policy file: $cluster_trust_policy"
  echo "Node policy file: $node_trust_policy"
}

# Function to delete IAM roles and detach policies
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
