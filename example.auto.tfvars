# =========================
# Example Auto TFVars for Local Testing
# =========================

# =========================
# Required Variables
# =========================

# Azure region for deployment
location = "East US 2"

# Naming convention object
naming = {
  application_code = "INFR"
  environment      = "D"
  correlative      = "90"
  objective_code   = "INFR" # Changed from "TEST" to allowed value
  region_code      = "EU2"
}

# =========================
# Configuration Objects
# =========================

# Resource Group Configuration
rg_config = {
  subscription_id = "0a5095ad-a860-4c57-aa7a-53276e51e748"
  tags = {
    Environment = "Development"
    Project     = "Demo Resource Group"
    Owner       = "DevOps Team"
    CostCenter  = "IT-001"
    CreatedBy   = "Terraform"
    Purpose     = "Local Testing"
  }
  lock = null
}

# Storage Account Configuration
stac_config = {
  # Storage settings
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

  # Optional storage container
  storage_container = null

  # Data retention
  retention_days = 14

  # Network access
  firewall_ips    = []
  vnet_subnet_ids = []

  # RBAC assignments
  role_assignments = {}
}

# Log Analytics Configuration
law_config = {
  allow_resource_only_permissions = false
  cmk_for_query_forced            = false
  internet_ingestion_enabled      = false
  internet_query_enabled          = false
  role_assignments                = {}
}

# Key Vault Configuration
keyvault_config = {
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
