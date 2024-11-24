#!/bin/bash

# Check if VPC ID is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <vpc-id>"
  exit 1
fi

# Input VPC ID
VPC_ID=$1

# Create Security Group
echo "Creating Security Group for Kubernetes cluster and nodes..."
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
  --group-name KubernetesClusterSG \
  --description "Security group for Kubernetes cluster and nodes" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

if [ $? -ne 0 ]; then
  echo "Failed to create security group. Exiting."
  exit 1
fi

echo "Security Group created: $SECURITY_GROUP_ID"

# Add Tags to the Security Group
echo "Adding tags to the Security Group..."
aws ec2 create-tags --resources $SECURITY_GROUP_ID --tags Key=Name,Value=KubernetesClusterSG Key=Environment,Value=Production

if [ $? -ne 0 ]; then
  echo "Failed to add tags to the Security Group."
  exit 1
fi
echo "Tags added successfully."

# Add Inbound Rules
echo "Adding inbound rules to the Security Group..."

# Allow SSH access (port 22)
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0

# Allow Kubernetes API server (port 6443)
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 6443 --cidr 0.0.0.0/0

# Allow etcd (port 2379-2380)
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 2379-2380 --source-group $SECURITY_GROUP_ID

# Allow kubelet and metrics-server (port 10250-10255)
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 10250-10255 --source-group $SECURITY_GROUP_ID

# Allow NodePort services (port 30000-32767)
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 30000-32767 --cidr 0.0.0.0/0

# Allow all traffic within the security group
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol -1 --source-group $SECURITY_GROUP_ID

# Check if default outbound rule exists
EXISTING_OUTBOUND_RULE=$(aws ec2 describe-security-groups --group-ids $SECURITY_GROUP_ID \
  --query 'SecurityGroups[0].IpPermissionsEgress' --output text)

if [ -z "$EXISTING_OUTBOUND_RULE" ]; then
  # Add Outbound Rules
  echo "Adding outbound rule to allow all traffic..."
  aws ec2 authorize-security-group-egress --group-id $SECURITY_GROUP_ID --protocol -1 --cidr 0.0.0.0/0
else
  echo "Outbound rule to allow all traffic already exists. Skipping."
fi

echo "Security Group setup completed. Security Group ID: $SECURITY_GROUP_ID"
