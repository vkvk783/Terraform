# 1. Resource Groups
module "resource_groups" {
  source   = "./modules/resource_group"
  for_each = merge(var.environments, {
    devops = {
      node_count  = 0
      vm_size     = ""
      max_count   = 0
      subnet_cidr = ""
      az_spread   = false
    }
  })
  name     = "rg-${var.project}-${each.key}"
  location = var.location
  tags = {
    environment = each.key
    project     = var.project
    managed-by  = "terraform"
  }
}

# 2. Log Analytics Workspace
module "log_analytics" {
  source              = "./modules/monitoring"
  resource_group_name = module.resource_groups["prod"].name
  workspace_name      = "law-${var.project}"
  location            = var.location
}

# 3. Virtual Network + Subnets
module "networking" {
  source              = "./modules/networking"
  resource_group_name = module.resource_groups["prod"].name
  vnet_name           = "vnet-${var.project}"
  vnet_cidr           = "10.0.0.0/8"
  location            = var.location
  subnets = merge(
    { for env, cfg in var.environments : "snet-${env}" => cfg.subnet_cidr },
    { "snet-devops" = var.devops_subnet_cidr }
  )
}

# 4. Azure Container Registry
module "acr" {
  source               = "./modules/acr"
  resource_group_name  = module.resource_groups["prod"].name
  acr_name             = "acr${var.project}"
  location             = var.location
  sku                  = "Premium"
  geo_replica_location = "westus"
}

# 5. Key Vaults — one per environment
module "key_vaults" {
  source              = "./modules/key_vault"
  for_each            = var.environments
  name                = "kv-${var.project}-${each.key}"
  resource_group_name = module.resource_groups[each.key].name
  location            = var.location
  tenant_id           = var.tenant_id
  soft_delete_days    = 90
  purge_protection    = each.key == "prod" ? true : false
}

# 6. AKS Clusters — one per environment
module "aks" {
  source              = "./modules/aks"
  for_each            = var.environments
  cluster_name        = "aks-${var.project}-${each.key}"
  resource_group_name = module.resource_groups[each.key].name
  location            = var.location
  node_count          = each.value.node_count
  vm_size             = each.value.vm_size
  max_count           = each.value.max_count
  subnet_id           = module.networking.subnet_ids["snet-${each.key}"]
  acr_id              = module.acr.id
  log_analytics_id    = module.log_analytics.workspace_id
  availability_zones  = each.value.az_spread ? [1, 2, 3] : []
}

# 7. Jenkins VM
module "devops_vms" {
  source              = "./modules/jenkins_vm"
  resource_group_name = module.resource_groups["devops"].name
  location            = var.location
  jenkins_vm_size     = var.jenkins_vm_size
  admin_ssh_key       = var.admin_ssh_key
  subnet_id           = module.networking.subnet_ids["snet-devops"]
}

# 9. SonarQube + Nexus VMs
module "sonarqube_nexus" {
  source              = "./modules/sonarqube_nexus"
  resource_group_name = module.resource_groups["devops"].name
  location            = var.location
  admin_ssh_key       = var.admin_ssh_key
  subnet_id           = module.networking.subnet_ids["snet-devops"]
}