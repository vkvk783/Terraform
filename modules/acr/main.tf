resource "azurerm_container_registry" "main" {
  name                = "${var.acr_name}prod01"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = false   # Use Managed Identity — no username/password

  georeplications {
    location                = var.geo_replica_location
    zone_redundancy_enabled = false
  }
}

output "id"           { value = azurerm_container_registry.main.id }
output "login_server" { value = azurerm_container_registry.main.login_server }