# terraform/modules/aks/main.tf
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.cluster_name
  kubernetes_version  = "1.33"

  default_node_pool {
    name                = "system"
    node_count          = var.node_count
    vm_size             = var.vm_size
    min_count           = 1
    max_count           = var.max_count
    enable_auto_scaling = true
    vnet_subnet_id      = var.subnet_id
    zones               = var.availability_zones
    os_disk_size_gb     = 50
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = "172.16.0.0/16"
    dns_service_ip    = "172.16.0.10"
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_id
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  azure_policy_enabled              = true
  role_based_access_control_enabled = true

  lifecycle { prevent_destroy = false }
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

output "cluster_name"       { value = azurerm_kubernetes_cluster.main.name }
output "kube_config"        { 
    value = azurerm_kubernetes_cluster.main.kube_config_raw
    sensitive = true 
    }
output "kubelet_identity"   { value = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id }