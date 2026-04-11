resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  address_space       = [var.vnet_cidr]
  location            = var.location
  resource_group_name = var.resource_group_name

}

resource "azurerm_subnet" "main" {
  for_each             = var.subnet
  name                 = each.key   
  resource_group_name = "var.resource_group_name"
  virtual_network_name = "var.vnet_name"
  address_prefixes    = [each.value]
}

output "subnet_ids" {
  value = { for s in azurerm_subnet.main : s.name => s.id }
}

