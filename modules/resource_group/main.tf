resource "azurerm_resource_group" "main" {
  name     = var.name
  location = var.location
  tags     = var.tags
}

output "name"     { value = azurerm_resource_group.main.name }
output "location" { value = azurerm_resource_group.main.location }