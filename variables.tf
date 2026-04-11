# terraform/variables.tf
variable "subscription_id" { type = string } #Azure subscription ID
variable "tenant_id" { type = string }       #Azure tenant ID

# Add this to terraform/variables.tf
variable "devops_subnet_cidr" {
  type    = string
  default = "10.0.10.0/24"
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "Primary Azure region for all resources"
}

variable "project" {
  type        = string
  default     = "taskmanager"
  description = "Project prefix used in all resource names"
}

variable "jenkins_vm_size" {
  type        = string
  default     = "Standard_D4s_v3"
  description = "VM size for Jenkins build server"
}

variable "admin_ssh_key" {
  type        = string
  description = "RSA public key content for Jenkins VM"
}

# Map of environment configs — for_each loops over all 4 environments
variable "environments" {
  type = map(object({
    node_count  = number
    vm_size     = string
    max_count   = number
    subnet_cidr = string
    az_spread   = bool # true = spread across availability zones
  }))
  default = {
    dev = { node_count = 2, vm_size = "Standard_D2s_v3", max_count = 4,
    subnet_cidr = "10.1.0.0/16", az_spread = false }
    test = { node_count = 2, vm_size = "Standard_D2s_v3", max_count = 4,
    subnet_cidr = "10.2.0.0/16", az_spread = false }
    uat = { node_count = 3, vm_size = "Standard_D4s_v3", max_count = 6,
    subnet_cidr = "10.3.0.0/16", az_spread = true }
    prod = { node_count = 3, vm_size = "Standard_D4s_v3", max_count = 10,
    subnet_cidr = "10.4.0.0/16", az_spread = true }
  }
}