// =========================
// Required Variables
// =========================

variable "location" {
  description = "Azure region for deployment."
  type        = string
  nullable    = false
  validation {
    condition     = length(trim(var.location, " ")) > 0
    error_message = "The location must not be empty."
  }
}

variable "naming" {
  description = "Base naming convention settings."
  type = object({
    application_code = optional(string, null)
    environment      = optional(string, null)
    correlative      = optional(string, null)
    objective_code   = optional(string, "INFR")
  })
  default = {
    application_code = "GEIA"
    environment      = "D"
    correlative      = "01"
    objective_code   = "INFR"
  }
}

variable "naming_override" {
  description = "Override naming convention settings for environment."
  type = object({
    application_code = optional(string)
    environment      = optional(string)
    correlative      = optional(string)
    objective_code   = optional(string)
  })
  default = {
    application_code = "GEIA"
    environment      = "D"
    correlative      = "01"
    objective_code   = "INFR"
  }
}

locals {
  merged_naming = merge(var.naming, var.naming_override)
  naming_valid_application_code = (
    local.merged_naming.application_code == null ? true : can(regex("^[a-zA-Z0-9]{4}$", local.merged_naming.application_code))
  )
  naming_valid_environment = (
    local.merged_naming.environment == null ? true : contains(["P", "C", "D", "F"], local.merged_naming.environment)
  )
  naming_valid_correlative = (
    local.merged_naming.correlative == null ? true : can(regex("^[0-9]{2}$", local.merged_naming.correlative))
  )
  naming_valid_objective_code = (
    local.merged_naming.objective_code == null ? true : (local.merged_naming.objective_code == "" ? true : can(regex("^[A-Za-z]{3,4}$", local.merged_naming.objective_code)))
  )
}

output "debug_naming" {
  value       = var.naming
  description = "Debug: Shows the naming object as loaded from tfvars or defaults."
}
output "debug_naming_override" {
  value       = var.naming_override
  description = "Debug: Shows the naming override object as loaded from tfvars or defaults."
}

output "debug_merged_naming" {
  value = local.merged_naming
  description = "Debug: Shows the merged naming object after combining naming and naming_override."
}

resource "null_resource" "naming_validation" {
  count = local.naming_valid_application_code && local.naming_valid_environment && local.naming_valid_correlative && local.naming_valid_objective_code ? 0 : 1
  provisioner "local-exec" {
    command = "echo 'Naming validation failed. Please check your naming and naming_override variables.' && exit 1"
  }
}

// =========================
// Configuration Objects
// =========================

variable "rg_config" {
  description = "Resource Group configuration settings."
  type = object({
    subscription_id = string
    tags = optional(map(string), {})
    lock = optional(object({
      kind = string
      name = optional(string)
    }), null)
  })
  default = {
    subscription_id = "value-not-set"
    tags = {}
    lock = null
  }

  validation {
    condition     = var.rg_config.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.rg_config.lock.kind) : true
    error_message = "Lock kind must be either 'CanNotDelete' or 'ReadOnly'."
  }
}

variable "stac_config" {
  description = "Storage account configuration settings."
  type = object({
    account_replication_type          = optional(string, "LRS")
    account_tier                      = optional(string, "Standard")
    account_kind                      = optional(string, "StorageV2")
    access_tier                       = optional(string, "Hot")
    large_file_share_enabled          = optional(bool, false)
    is_hns_enabled                    = optional(bool, false)
    nfsv3_enabled                     = optional(bool, false)
    sftp_enabled                      = optional(bool, false)
    queue_encryption_key_type         = optional(string, "Service")
    table_encryption_key_type         = optional(string, "Service")
    infrastructure_encryption_enabled = optional(bool, false)
    blob_versioning_enabled           = optional(bool, false)
    blob_change_feed_enabled          = optional(bool, false)
    storage_container = optional(object({
      name                  = string
      container_access_type = optional(string, "private")
    }), null)
    retention_days  = optional(number, 14)
    firewall_ips    = optional(list(string), [])
    vnet_subnet_ids = optional(list(string), [])
    tags            = optional(map(string), {})
    lock = optional(object({
      kind = string
      name = optional(string)
    }), null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      principal_type                         = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})
  })
  default = {
    account_replication_type          = "LRS"
    account_tier                      = "Standard"
    account_kind                      = "StorageV2"
    access_tier                       = "Hot"
    large_file_share_enabled          = false
    is_hns_enabled                    = false
    nfsv3_enabled                     = false
    sftp_enabled                      = false
    queue_encryption_key_type         = "Service"
    table_encryption_key_type         = "Service"
    infrastructure_encryption_enabled = false
    blob_versioning_enabled           = false
    blob_change_feed_enabled          = false
    storage_container                 = null
    retention_days                    = 14
    firewall_ips                      = []
    vnet_subnet_ids                   = []
    tags                              = {}
    lock                              = null
    role_assignments                  = {}
  }

  validation {
    condition     = var.stac_config.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.stac_config.lock.kind) : true
    error_message = "Storage account lock kind must be either 'CanNotDelete' or 'ReadOnly'."
  }
}

variable "keyvault_config" {
  description = "Key Vault configuration settings."
  type = object({
    sku_name                        = optional(string, "premium")
    enabled_for_disk_encryption     = optional(bool, true)
    enabled_for_deployment          = optional(bool, false)
    enabled_for_template_deployment = optional(bool, false)
    purge_protection_enabled        = optional(bool, true)
    soft_delete_retention_days      = optional(number, 90)
    public_network_access_enabled   = optional(bool, false)
    network_acls = optional(object({
      bypass                     = optional(string, "AzureServices")
      default_action             = optional(string, "Deny")
      ip_rules                   = optional(list(string), [])
      virtual_network_subnet_ids = optional(list(string), [])
      }), {
      bypass                     = "AzureServices"
      default_action             = "Deny"
      ip_rules                   = []
      virtual_network_subnet_ids = []
    })
  })
  default = {
    sku_name                        = "premium"
    enabled_for_disk_encryption     = true
    enabled_for_deployment          = false
    enabled_for_template_deployment = false
    purge_protection_enabled        = true
    soft_delete_retention_days      = 90
    public_network_access_enabled   = false
    network_acls = {
      bypass                     = "AzureServices"
      default_action             = "Deny"
      ip_rules                   = []
      virtual_network_subnet_ids = []
    }
  }
}

variable "law_config" {
  description = "Log Analytics workspace configuration settings."
  type = object({
    allow_resource_only_permissions = optional(bool, false)
    cmk_for_query_forced            = optional(bool, false)
    internet_ingestion_enabled      = optional(bool, false)
    internet_query_enabled          = optional(bool, false)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      principal_type                         = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})
  })
  default = {
    allow_resource_only_permissions = false
    cmk_for_query_forced            = false
    internet_ingestion_enabled      = false
    internet_query_enabled          = false
    role_assignments                = {}
  }
}

# variable "resource_group_name" {
#   description = "Optional: Name of existing resource group to use. If not provided, a new resource group will be created using the naming convention."
#   type        = string
#   default     = null
#   nullable    = true

#   validation {
#     condition     = var.resource_group_name == null ? true : length(var.resource_group_name) > 0
#     error_message = "If provided, resource_group_name must not be empty."
#   }
# }

// =========================