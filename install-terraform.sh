#!bin/bash

sudo apt-get update && sudo apt-get install -y gnupg software-properties-common


echo "Installing the HashiCorp GPG key."
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null


echo "Verify the key's fingerprint."
gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint

echo "command finds the distribution release codename for your current system:"

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

echo "Download the package information from HashiCorp:"
sudo apt update

echo "Install Terraform from the new repository."
sudo apt-get install terraform
