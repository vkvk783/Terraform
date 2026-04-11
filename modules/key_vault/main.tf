resource "azurerm_key_vault" "main" {
  name                      = "${var.name}01"
  resource_group_name       = var.resource_group_name
  location                  = var.location
  tenant_id                 = var.tenant_id
  sku_name                  = "standard"
  soft_delete_retention_days = var.soft_delete_days
  purge_protection_enabled  = var.purge_protection
  enable_rbac_authorization = true   # Use RBAC instead of access policies
}

output "id"   { value = azurerm_key_vault.main.id }
output "name" { value = azurerm_key_vault.main.name }