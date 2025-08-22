# =========================
# Updated terraform.tfvars to match new variable structure
# =========================

# Location - use the display name format expected by child modules  
location = "East US"

# Naming configuration object
naming = {
  application_code = "CORE"
  objective_code   = "SEGU"
  environment      = "D"
  correlative      = "99"
}

# Resource Group configuration
rg_config = {
  tags = {
    Environment = "Development"
    Project     = "GEIA Example"
  }
  lock = null
}

# Storage Account configuration (using defaults from variables.tf)
stac_config = {
  # Enable deployment mode to allow shared access keys during deployment
  enable_deployment_mode    = true # This forces shared_access_key_enabled = true
  shared_access_key_enabled = true # Explicit setting (recommended for clarity)
}

# Log Analytics configuration (using defaults from variables.tf) 
law_config = {}

# Log Analytics configuration (using defaults from variables.tf) 
keyvault_config = {

  tenant_id                       = "00000000-0000-0000-0000-000000000000" # Replace with your Azure tenant ID
  sku_name                        = "standard"                             # Premium for testing (includes HSM)
  enabled_for_disk_encryption     = true                                   # Allow Azure Disk Encryption
  enabled_for_deployment          = false                                  # Disable VM deployment access
  enabled_for_template_deployment = false                                  # Disable ARM template access
  purge_protection_enabled        = true                                   # Enable purge protection
  soft_delete_retention_days      = 90                                     # 90-day retention for deleted keys
  public_network_access_enabled   = false                                  # Disable public access

  network_acls = {
    bypass         = "AzureServices" # Allow trusted Azure services
    default_action = "Deny"          # Deny all other access by default
    ip_rules = [
      # Add your public IP addresses here for testing access
      # "203.0.113.1",  # Example: Your office IP
      # "203.0.113.2"   # Example: Your home IP
    ]
    virtual_network_subnet_ids = [] # No VNet integration for basic testing
  }

  diagnostic_settings = {
    default = {
      name                       = "default"
      log_analytics_workspace_id = "/subscriptions/12345678-1234-9876-4563-123456789012/resourceGroups/example-resource-group/providers/Microsoft.OperationalInsights/workspaces/workspaceName" # Replace with your Log Analytics Workspace resource ID

      # Optional: logs and metrics use defaults if omitted, but you can specify them explicitly:
      enabled_logs = [
        {
          category_group = "audit"
        }
      ]
      metrics = [
        {
          category = "AllMetrics"
          enabled  = true
        }
      ]
    }
  }
}    
