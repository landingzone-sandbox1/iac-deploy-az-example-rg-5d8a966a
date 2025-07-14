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
  description = "Naming convention settings for all resources. All fields are optional to allow workspace-specific overrides."
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

  validation {
    condition = (
      var.naming.application_code == null || 
      can(regex("^[a-zA-Z0-9]{4}$", var.naming.application_code))
    )
    error_message = "When provided, application_code must be exactly 4 alphanumeric characters."
  }

  validation {
    condition = (
      var.naming.environment == null || 
      contains(["P", "C", "D", "F"], var.naming.environment)
    )
    error_message = "When provided, environment must be one of: P, C, D, F."
  }

  validation {
    condition = (
      var.naming.correlative == null || 
      can(regex("^[0-9]{2}$", var.naming.correlative))
    )
    error_message = "When provided, correlative must be two digits."
  }

  validation {
    condition = (
      var.naming.objective_code == "" || 
      can(regex("^[A-Za-z]{3,4}$", var.naming.objective_code))
    )
    error_message = "When provided, objective_code can be 3 or 4 letters."
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