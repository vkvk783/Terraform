variable "resource_group_name" {
  type        = string
  description = "Resource group where Log Analytics Workspace will be created"
}

variable "workspace_name" {
  type        = string
  description = "Name of the Log Analytics Workspace"
}

variable "location" {
  type        = string
  description = "Azure region for the workspace"
}
