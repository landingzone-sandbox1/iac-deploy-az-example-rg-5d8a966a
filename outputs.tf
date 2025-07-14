output "id" {
  description = "The ID of the deployed Resource Group"
  value       = module.azure_rg_example.resource_group_id
}

output "name" {
  description = "The name of the deployed Resource Group"
  value       = module.azure_rg_example.resource_group_name
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics workspace from the module."
  value       = module.azure_rg_example.log_analytics_workspace_name
}

output "log_analytics_workspace_id" {
  description = "The resource ID of the Log Analytics workspace from the module."
  value       = module.azure_rg_example.log_analytics_workspace_id
}

# output "storage_account" {
#   description = "Object containing key storage account outputs."
#   value       = module.azure_rg_example.storage_account
# }

output "storage_account" {
  description = "Object containing key storage account outputs."
  value       = module.azure_rg_example.storage_account
}



output "debug_naming" {
  value = var.naming
}