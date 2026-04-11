variable "cluster_name"        { type = string }
variable "location"            { type = string }
variable "resource_group_name" { type = string }
variable "node_count"          { type = number }
variable "vm_size"             { type = string }
variable "max_count"           { type = number }
variable "subnet_id"           { type = string }
variable "acr_id"              { type = string }
variable "log_analytics_id"    { type = string }
variable "availability_zones"  {
  type    = list(number)
  default = []
}