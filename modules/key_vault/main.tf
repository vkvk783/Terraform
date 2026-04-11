resource "azure_key_vault" "main" {
  name                        = var.name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = var.soft_delete_days
  purge_protection_enabled    = var.purge_protection
  enabled_rbac_authorization      = true
}

output "id" {
  value = azure_key_vault.main.id
}
output "name" {
  value = azure_key_vault.main.name
}