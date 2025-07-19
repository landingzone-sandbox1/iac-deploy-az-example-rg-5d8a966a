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
  description = "Key Vault configuration. Must include resource_group_name (existing), name, sku_name, and diagnostic_settings (mandatory for security compliance)."
  type = object({
    # Required
    tenant_id = string # Azure tenant ID for authentication

    # Basic Configuration (with defaults)
    enabled_for_deployment          = optional(bool, false)       # VM certificate access 
    enabled_for_template_deployment = optional(bool, false)       # ARM template access
    sku_name                        = optional(string, "premium") # standard, premium

    # Security and Network Configuration (environment-specific)
    purge_protection_enabled      = optional(bool)       # Enable/disable purge protection (null = auto based on environment)
    public_network_access_enabled = optional(bool)       # Enable/disable public network access (null = default false)
    soft_delete_retention_days    = optional(number, 90) # Soft delete retention period

    # Resource Management
    resource_group_name = optional(object({
      create_new = bool
      name       = optional(string, null)
    }))
    lock = optional(object({
      kind = string # CanNotDelete, ReadOnly
      name = optional(string, null)
    }))

    # Network Access Control
    network_acls = optional(object({
      bypass                     = optional(string, "AzureServices") # AzureServices, None
      default_action             = optional(string, "Deny")          # Allow, Deny
      ip_rules                   = optional(list(string), [])        # CIDR blocks
      virtual_network_subnet_ids = optional(list(string), [])        # Subnet IDs
    }))

    # Legacy Access Policies (for backwards compatibility)
    legacy_access_policies_enabled = optional(bool, false)
    legacy_access_policies = optional(map(object({
      object_id               = string
      application_id          = optional(string)
      certificate_permissions = optional(list(string))
      key_permissions         = optional(list(string))
      secret_permissions      = optional(list(string))
      storage_permissions     = optional(list(string))
    })), {})

    # Private Endpoints
    private_endpoints = optional(map(object({
      subnet_resource_id              = string
      private_dns_zone_resource_ids   = optional(list(string), [])
      private_dns_zone_group_name     = optional(string, "default")
      private_service_connection_name = optional(string)
      name                            = optional(string)
      location                        = optional(string)
      resource_group_name             = optional(string)
      is_manual_connection            = optional(bool, false)
      ip_configurations = optional(map(object({
        name               = string
        private_ip_address = string
      })), {})
      tags = optional(map(string), {})
    })), {})

    # Key Vault Keys
    keys = optional(map(object({
      name     = string
      key_type = string                 # RSA, EC, RSA-HSM, EC-HSM
      key_size = optional(number, 2048) # For RSA keys: 2048, 3072, 4096
      curve    = optional(string)       # For EC keys: P-256, P-384, P-521, P-256K
      key_opts = list(string)           # decrypt, encrypt, sign, unwrapKey, verify, wrapKey

      rotation_policy = optional(object({
        automatic = optional(object({
          time_after_creation = optional(string) # ISO 8601 duration
          time_before_expiry  = optional(string) # ISO 8601 duration
        }))
        expire_after         = optional(string) # ISO 8601 duration
        notify_before_expiry = optional(string) # ISO 8601 duration
      }))

      not_before_date = optional(string) # RFC 3339 date
      expiration_date = optional(string) # RFC 3339 date
      tags            = optional(map(string), {})
    })), {})

    # Key Vault Secrets
    secrets = optional(map(object({
      name            = string
      value           = optional(string) # Optional - enables template secrets without values
      content_type    = optional(string) # MIME type
      not_before_date = optional(string) # RFC 3339 date
      expiration_date = optional(string) # RFC 3339 date
      tags            = optional(map(string), {})
    })), {})

    # Key Vault Certificates
    certificates = optional(map(object({
      name = string

      # Certificate Policy
      certificate_policy = object({
        issuer_parameters = object({
          name = string # Self, Unknown, or certificate authority name
        })

        key_properties = object({
          exportable = bool
          key_size   = number
          key_type   = string # RSA, EC
          reuse_key  = bool
        })

        lifetime_actions = optional(list(object({
          action = object({
            action_type = string # AutoRenew, EmailContacts
          })
          trigger = object({
            days_before_expiry  = optional(number)
            lifetime_percentage = optional(number)
          })
        })), [])

        secret_properties = object({
          content_type = string # application/x-pkcs12, application/x-pem-file
        })

        x509_certificate_properties = optional(object({
          extended_key_usage = optional(list(string), [])
          key_usage          = list(string)
          subject            = string
          validity_in_months = number

          subject_alternative_names = optional(object({
            dns_names = optional(list(string), [])
            emails    = optional(list(string), [])
            upns      = optional(list(string), [])
          }))
        }))
      })

      # Certificate attributes
      not_before_date = optional(string)
      expiration_date = optional(string)
      tags            = optional(map(string), {})
    })), {})

    # Resource Tags
    tags = optional(map(string), {})

    # LT-4: Diagnostic Settings for Security Investigation (NUEVO LBS) - MANDATORY
    diagnostic_settings = map(object({
      name                       = string
      log_analytics_workspace_id = string # REQUIRED - only Log Analytics allowed

      # LBS requirement: AuditEvent logs for security investigation
      enabled_logs = optional(list(object({
        category       = optional(string)
        category_group = optional(string)
        })), [
        {
          category_group = "audit" # Required by LBS for AuditEvent logs
        }
      ])

      # Performance and security metrics
      metrics = optional(list(object({
        category = string
        enabled  = optional(bool, true)
        })), [
        {
          category = "AllMetrics"
          enabled  = true
        }
      ])
    }))
  })

  # Tenant ID validation
  validation {
    condition     = var.keyvault_config.tenant_id == null || can(regex("^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$", var.keyvault_config.tenant_id))
    error_message = "The tenant ID must be a valid GUID with lowercase letters, or null to auto-detect."
  }

  # Lock validation
  validation {
    condition     = var.keyvault_config.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.keyvault_config.lock.kind) : true
    error_message = "Lock kind must be either 'CanNotDelete' or 'ReadOnly'."
  }

  # LT-4: Diagnostic Settings validation - mandatory for security compliance
  validation {
    condition     = length(var.keyvault_config.diagnostic_settings) > 0
    error_message = "At least one diagnostic setting must be configured for security compliance (LT-4 requirement)."
  }

  # Diagnostic Settings Log Analytics validation
  validation {
    condition = alltrue([
      for k, v in var.keyvault_config.diagnostic_settings : v.log_analytics_workspace_id != null && v.log_analytics_workspace_id != ""
    ])
    error_message = "All diagnostic settings must have a valid log_analytics_workspace_id. Only Log Analytics is allowed as destination."
  }

  # SKU validation
  validation {
    condition = (
      (var.naming.environment == "P" && var.keyvault_config.sku_name == "premium") ||
      (contains(["C", "D", "F"], var.naming.environment) && var.keyvault_config.sku_name == "standard")
    )
    error_message = "The SKU name must be 'premium' for Production (P) environment, and 'standard' for Certification (C), Development (D), or Infrastructure (F) environments."
  }

  # Key validation
  validation {
    condition = alltrue([
      for k, v in var.keyvault_config.keys : contains(["RSA", "EC", "RSA-HSM", "EC-HSM"], v.key_type)
    ])
    error_message = "Key type must be one of: RSA, EC, RSA-HSM, EC-HSM."
  }

  # Legacy Access Policy validation for P, D, C environments
  validation {
    condition = (
      !var.keyvault_config.legacy_access_policies_enabled ||
      !contains(["P", "D", "C"], var.naming.environment) ||
      alltrue([
        for ap in values(var.keyvault_config.legacy_access_policies) : (
          # Key management operations
          alltrue([
            contains([for p in ap.key_permissions : lower(p)], "get"),
            contains([for p in ap.key_permissions : lower(p)], "list"),
            contains([for p in ap.key_permissions : lower(p)], "create"),
            contains([for p in ap.key_permissions : lower(p)], "recover"),
            contains([for p in ap.key_permissions : lower(p)], "delete"),
            contains([for p in ap.key_permissions : lower(p)], "restore"),
            contains([for p in ap.key_permissions : lower(p)], "purge"),
            # Cryptographic operations (all)
            contains([for p in ap.key_permissions : lower(p)], "decrypt"),
            contains([for p in ap.key_permissions : lower(p)], "encrypt"),
            contains([for p in ap.key_permissions : lower(p)], "unwrapkey"),
            contains([for p in ap.key_permissions : lower(p)], "wrapkey"),
            contains([for p in ap.key_permissions : lower(p)], "verify"),
            contains([for p in ap.key_permissions : lower(p)], "sign"),
            # Rotation policy
            contains([for p in ap.key_permissions : lower(p)], "getrotationpolicy")
          ])
        )
      ])
    )
    error_message = <<-EOT
      For environments P, D, or C, all legacy access policies must include:
      - Key management: get, list, create, recover, delete, restore, purge
      - Cryptographic: decrypt, encrypt, unwrapKey, wrapKey, verify, sign
      - Rotation policy: getrotationpolicy
    EOT
  }
  # Legacy Access Policy validation for Infrastructure environment F
  validation {
    condition = (
      !var.keyvault_config.legacy_access_policies_enabled ||
      var.naming.environment != "F" ||
      alltrue([
        for ap in values(var.keyvault_config.legacy_access_policies) : (
          contains([for p in ap.secret_permissions : lower(p)], "get")
        )
      ])
    )
    error_message = "For Infrastructure environment F, all legacy access policies must include 'get' in secret_permissions."
  }

  # Secret name validation - ensure consistent naming
  validation {
    condition = alltrue([
      for k, v in var.keyvault_config.secrets : can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$|^[a-zA-Z0-9]$", v.name))
    ])
    error_message = "Secret names must start and end with alphanumeric characters, and can contain hyphens in the middle. Single character names are allowed."
  }

  # Secret value validation - when provided, must not be empty
  validation {
    condition = alltrue([
      for k, v in var.keyvault_config.secrets : (
        v.value == null || length(v.value) >= 1
      )
    ])
    error_message = "Secret values must be either null (template-only) or contain at least 1 character. Empty strings are not allowed."
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