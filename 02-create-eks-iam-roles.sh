#!/bin/bash

# Set the cluster name as a variable
CLUSTER_NAME="my-eks-cluster01"

# IAM role names
CLUSTER_ROLE_NAME="${CLUSTER_NAME}-cluster-role"
NODE_ROLE_NAME="${CLUSTER_NAME}-node-role"

# Trust policy JSON files
CLUSTER_TRUST_POLICY="eks-cluster-trust-policy.json"
NODE_TRUST_POLICY="eks-node-trust-policy.json"

# Create the trust policy files
cat <<EOT > $CLUSTER_TRUST_POLICY
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

cat <<EOT > $NODE_TRUST_POLICY
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

# Create the IAM role for the EKS cluster
echo "Creating IAM role for EKS cluster..."
aws iam create-role --role-name $CLUSTER_ROLE_NAME --assume-role-policy-document file://$CLUSTER_TRUST_POLICY

# Attach the required policy to the cluster role
echo "Attaching policy to EKS cluster role..."
aws iam attach-role-policy --role-name $CLUSTER_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

# Create the IAM role for the node group
echo "Creating IAM role for EKS node group..."
aws iam create-role --role-name $NODE_ROLE_NAME --assume-role-policy-document file://$NODE_TRUST_POLICY

# Attach the required policies to the node role
echo "Attaching policies to EKS node role..."
aws iam attach-role-policy --role-name $NODE_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
aws iam attach-role-policy --role-name $NODE_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
aws iam attach-role-policy --role-name $NODE_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy

# Verify the roles
echo "Verifying the created roles..."
aws iam list-roles | grep $CLUSTER_ROLE_NAME
aws iam list-roles | grep $NODE_ROLE_NAME

# Cleanup local policy files
rm -f $CLUSTER_TRUST_POLICY $NODE_TRUST_POLICY

echo "IAM roles for EKS cluster and node group have been created successfully."
