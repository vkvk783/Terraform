variable "resource_group_name"  { type = string }
variable "acr_name"             { type = string }
variable "location"             { type = string }
variable "sku" { 
    type = string
    default = "Premium" 
  }
variable "geo_replica_location"{ 
    type = string
    default = "westus" 
  }