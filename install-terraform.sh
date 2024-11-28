#!/bin/bash

# Update system and install prerequisites
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common wget lsb-release

# Add the HashiCorp GPG key
echo "Installing the HashiCorp GPG key."
wget -q -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

# Verify the GPG key fingerprint
echo "Verify the key's fingerprint."
gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint || {
    echo "GPG key verification failed. Exiting."
    exit 1
}

# Add the HashiCorp repository
echo "Adding the HashiCorp repository."
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update and install Terraform
echo "Updating package lists and installing Terraform."
sudo apt-get update && sudo apt-get install -y terraform || {
    echo "Terraform installation failed. Exiting."
    exit 1
}

echo "Terraform installation completed successfully."
