variable "name"                { type = string }
variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "tenant_id"           { type = string }
variable "soft_delete_days"    {
     type = number
     default = 90
  }
variable "purge_protection"    { 
    type = bool
    default = false
  }