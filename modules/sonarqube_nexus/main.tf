# ── SonarQube VM ─────────────────────────────────────────────────
resource "azurerm_network_interface" "sonar" {
  name                = "nic-sonarqube"
  resource_group_name = var.resource_group_name
  location            = var.location
  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.10.11"
  }
}

resource "azurerm_linux_virtual_machine" "sonarqube" {
  name                = "vm-sonarqube"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_D2s_v3"
  admin_username      = "azureuser"

  network_interface_ids = [azurerm_network_interface.sonar.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.admin_ssh_key
  }

  os_disk {
    name                 = "osdisk-sonarqube"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 64
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(<<-SCRIPT
    #!/bin/bash
    set -euxo pipefail
    apt-get update -y
    apt-get install -y openjdk-17-jdk unzip
    useradd -r -m -U -d /opt/sonarqube sonar
    wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-10.4.1.88267.zip -P /tmp
    unzip /tmp/sonarqube-10.4.1.88267.zip -d /opt
    mv /opt/sonarqube-10.4.1.88267 /opt/sonarqube
    chown -R sonar:sonar /opt/sonarqube
    echo "[Unit]
    Description=SonarQube service
    After=network.target
    [Service]
    Type=forking
    ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
    ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
    User=sonar
    Restart=always
    [Install]
    WantedBy=multi-user.target" > /etc/systemd/system/sonarqube.service
    systemctl enable --now sonarqube
  SCRIPT
  )

  tags = { managed-by = "terraform", role = "sonarqube" }
}

# ── Nexus VM ──────────────────────────────────────────────────────
resource "azurerm_network_interface" "nexus" {
  name                = "nic-nexus"
  resource_group_name = var.resource_group_name
  location            = var.location
  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.10.12"
  }
}

resource "azurerm_managed_disk" "nexus_data" {
  name                 = "disk-nexus-data"
  resource_group_name  = var.resource_group_name
  location             = var.location
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 128
}

resource "azurerm_linux_virtual_machine" "nexus" {
  name                = "vm-nexus"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_D2s_v3"
  admin_username      = "azureuser"

  network_interface_ids = [azurerm_network_interface.nexus.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.admin_ssh_key
  }

  os_disk {
    name                 = "osdisk-nexus"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 64
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(<<-SCRIPT
    #!/bin/bash
    set -euxo pipefail
    apt-get update -y
    apt-get install -y openjdk-8-jdk
    useradd -r -m -U -d /opt/nexus nexus
    wget https://download.sonatype.com/nexus/3/nexus-3.66.0-02-java8-unix.tar.gz -P /tmp
    tar -xzf /tmp/nexus-3.66.0-02-java8-unix.tar.gz -C /opt
    mv /opt/nexus-3.66.0-02 /opt/nexus
    chown -R nexus:nexus /opt/nexus /opt/sonatype-work 2>/dev/null || true
    echo "run_as_user=nexus" > /opt/nexus/bin/nexus.rc
    echo "[Unit]
    Description=Nexus Repository Manager
    After=network.target
    [Service]
    Type=forking
    ExecStart=/opt/nexus/bin/nexus start
    ExecStop=/opt/nexus/bin/nexus stop
    User=nexus
    Restart=always
    [Install]
    WantedBy=multi-user.target" > /etc/systemd/system/nexus.service
    systemctl enable --now nexus
  SCRIPT
  )

  tags = { managed-by = "terraform", role = "nexus" }
}

resource "azurerm_virtual_machine_data_disk_attachment" "nexus_data" {
  managed_disk_id    = azurerm_managed_disk.nexus_data.id
  virtual_machine_id = azurerm_linux_virtual_machine.nexus.id
  lun                = 0
  caching            = "ReadWrite"
}

output "sonarqube_private_ip" { value = azurerm_network_interface.sonar.private_ip_address }
output "nexus_private_ip"     { value = azurerm_network_interface.nexus.private_ip_address }