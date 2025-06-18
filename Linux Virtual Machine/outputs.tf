output "public_ip" {
  description = "Public IP to SSH into your VM"
  value       = azurerm_public_ip.public_ip.ip_address
}

output "ssh_command" {
  description = "Command to SSH into the VM"
  value       = "ssh azureuser@${azurerm_public_ip.public_ip.ip_address}"
}

output "jenkins_url" {
  description = "URL to access Jenkins web interface"
  value       = "http://${azurerm_public_ip.public_ip.ip_address}:8080"
}

output "installation_status_commands" {
  description = "Commands to check installation status"
  value = <<EOT
# Connect to the VM:
ssh azureuser@${azurerm_public_ip.public_ip.ip_address}

# Check cloud-init status:
cloud-init status

# View detailed cloud-init logs:
sudo cat /var/log/cloud-init-output.log

# View installation status file:
cat /home/azureuser/installation-status

# View detailed installation logs:
cat /var/log/installation-status.log

# Check Docker status:
systemctl status docker

# Check Jenkins status:
systemctl status jenkins

# Get Jenkins initial admin password:
cat /home/azureuser/.jenkins/initialAdminPassword
# or if that doesn't exist:
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
EOT
}
