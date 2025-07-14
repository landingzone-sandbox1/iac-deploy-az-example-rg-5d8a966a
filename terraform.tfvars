# =========================
# Updated terraform.tfvars to match new variable structure
# =========================

# Location - use the display name format expected by child modules  
location = "East US"

# Naming configuration object
naming = {
  application_code = "CORE"
  objective_code   = "INFR"
}

# Resource Group configuration
rg_config = {
  subscription_id = "5d8a966a-abb4-4e7b-831a-19ed1f768b8e"
  tags = {
    Environment = "Development"
    Project     = "GEIA Example"
  }
  lock = null
}

# Storage Account configuration (using defaults from variables.tf)
stac_config = {
  # Enable deployment mode to allow shared access keys during deployment
  enable_deployment_mode    = true   # This forces shared_access_key_enabled = true
  shared_access_key_enabled = true   # Explicit setting (recommended for clarity)
}

# Log Analytics configuration (using defaults from variables.tf) 
law_config = {}

# Key Vault configuration (using defaults from variables.tf)
keyvault_config = {}