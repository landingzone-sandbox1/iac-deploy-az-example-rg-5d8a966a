# =========================
# terraform.tfvars — listo
# =========================

location = "East US"

# Cambia 'correlative' si vuelve a chocar algún nombre (94, 95, …)
naming = {
  application_code = "INFR"
  objective_code   = "SVLS"
  environment      = "D"
  correlative      = "93"
}

# Resource Group
resource_group_config = {
  tags = {
    Environment = "Development"
    Project     = "GEIA Example"
  }
  lock = null
}

# Storage Account
storage_config = {
  enable_deployment_mode    = true
  shared_access_key_enabled = true

  tags = {
    Environment = "Development"
  }

  # Si necesitas forzar nombre único en vez de depender del naming:
  # name         = "staceu1infrsvlsd93jlm01"     # o
  # account_name = "staceu1infrsvlsd93jlm01"
}

# Log Analytics
log_analytics_config = {
  # vacío → defaults del módulo
}

# Key Vault
keyvault_config = {
  tenant_id = "831042d1-f40d-4dde-93fc-d04681888dd3"
  sku_name  = "standard"

  enabled_for_disk_encryption     = true
  enabled_for_deployment          = false
  enabled_for_template_deployment = false
  purge_protection_enabled        = true
  soft_delete_retention_days      = 90

  # Mientras no uses Private Endpoint/ACLs, deja true para no bloquearte
  public_network_access_enabled = true

  network_acls = {
    bypass         = "AzureServices"
    default_action = "Allow"   # si lo pones en "Deny", agrega ip_rules o VNets
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }
}
