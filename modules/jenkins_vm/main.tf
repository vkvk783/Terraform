# ─────────────────────────────────────────────────────────────────
# LOCAL — Inline cloud-init script (avoids external file dependency)
# ─────────────────────────────────────────────────────────────────
locals {
  jenkins_init_script = <<-SCRIPT
    #!/bin/bash
    set -euxo pipefail
    LOG=/var/log/jenkins-init.log
    exec > >(tee -a $LOG) 2>&1
    echo "=== Jenkins Init Start ==="
    apt-get update -y && apt-get upgrade -y
    apt-get install -y openjdk-17-jdk
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.asc
    echo 'deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/' | tee /etc/apt/sources.list.d/jenkins.list
    apt-get update -y && apt-get install -y jenkins
    systemctl enable --now jenkins
    curl -fsSL https://get.docker.com | bash
    usermod -aG docker jenkins
    systemctl enable --now docker
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash
    curl -LO https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    apt-get install -y gnupg software-properties-common
    curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo 'deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com jammy main' | tee /etc/apt/sources.list.d/hashicorp.list
    apt-get update -y && apt-get install -y terraform
    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
    curl -s https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh | bash && mv kustomize /usr/local/bin/
    apt-get install -y maven jq
    echo "=== Jenkins Init Complete ==="
  SCRIPT
}

# ─────────────────────────────────────────────────────────────────
# PUBLIC IP
# ─────────────────────────────────────────────────────────────────
resource "azurerm_public_ip" "jenkins" {
  name                = "pip-jenkins"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = { managed-by = "terraform" }
}

# ─────────────────────────────────────────────────────────────────
# NETWORK SECURITY GROUP
# ─────────────────────────────────────────────────────────────────
resource "azurerm_network_security_group" "jenkins" {
  name                = "nsg-jenkins"
  resource_group_name = var.resource_group_name
  location            = var.location

  security_rule {
    name                       = "allow-jenkins-8080"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-ssh-22"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-sonar-9000"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-nexus-8081"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8081"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = { managed-by = "terraform" }
}

# ─────────────────────────────────────────────────────────────────
# NETWORK INTERFACE
# ─────────────────────────────────────────────────────────────────
resource "azurerm_network_interface" "jenkins" {
  name                = "nic-jenkins"
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jenkins.id
  }

  tags = { managed-by = "terraform" }
}

# ─────────────────────────────────────────────────────────────────
# ASSOCIATE NSG WITH NIC
# ─────────────────────────────────────────────────────────────────
resource "azurerm_network_interface_security_group_association" "jenkins" {
  network_interface_id      = azurerm_network_interface.jenkins.id
  network_security_group_id = azurerm_network_security_group.jenkins.id
}

# ─────────────────────────────────────────────────────────────────
# JENKINS VIRTUAL MACHINE
# ─────────────────────────────────────────────────────────────────
resource "azurerm_linux_virtual_machine" "jenkins" {
  name                = "vm-jenkins"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.jenkins_vm_size
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.jenkins.id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.admin_ssh_key
  }

  os_disk {
    name                 = "osdisk-jenkins"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 100
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(local.jenkins_init_script)

  identity {
    type = "SystemAssigned"
  }

  tags = {
    managed-by = "terraform"
    role       = "jenkins-build-server"
  }
}

# ─────────────────────────────────────────────────────────────────
# OUTPUTS
# ─────────────────────────────────────────────────────────────────
output "jenkins_public_ip" {
  description = "Public IP of Jenkins VM — use for browser and GitHub webhook"
  value       = azurerm_public_ip.jenkins.ip_address
}

output "jenkins_private_ip" {
  description = "Private IP of Jenkins VM"
  value       = azurerm_network_interface.jenkins.private_ip_address
}

output "jenkins_vm_id" {
  description = "Resource ID of Jenkins VM"
  value       = azurerm_linux_virtual_machine.jenkins.id
}