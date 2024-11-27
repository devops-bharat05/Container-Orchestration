#!/bin/bash

# Jenkins Installation Script for Ubuntu
# Author: Your Name
# Date: $(date)

# Function to check if the script is run as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "This script must be run as root. Please use sudo."
        exit 1
    fi
}

# Update the system
update_system() {
    echo "Updating system packages..."
    apt update && apt upgrade -y
}

# Install Java (Jenkins requires Java)
install_java() {
    echo "Installing Java (OpenJDK 11)..."
    apt install -y openjdk-11-jdk
}

# Add Jenkins repository and GPG key
add_jenkins_repo() {
    echo "Adding Jenkins repository..."
    curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/" | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null
}

# Install Jenkins
install_jenkins() {
    echo "Installing Jenkins..."
    apt update
    apt install -y jenkins
}

# Start and enable Jenkins service
start_jenkins() {
    echo "Starting Jenkins service..."
    systemctl start jenkins
    systemctl enable jenkins
}

# Display initial admin password
display_password() {
    echo "Fetching Jenkins initial admin password..."
    ADMIN_PASSWORD_FILE="/var/lib/jenkins/secrets/initialAdminPassword"
    if [ -f "$ADMIN_PASSWORD_FILE" ]; then
        echo "Initial Admin Password:"
        cat "$ADMIN_PASSWORD_FILE"
    else
        echo "Failed to retrieve the initial admin password. Please check manually."
    fi
}

# Main script execution
main() {
    check_root
    update_system
    install_java
    add_jenkins_repo
    install_jenkins
    start_jenkins
    display_password
    echo "Jenkins installation completed successfully!"
    echo "Access Jenkins at: http://<server-ip>:8080"
}

# Run the script
main
