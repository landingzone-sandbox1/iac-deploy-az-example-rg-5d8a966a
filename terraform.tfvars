# =========================
# terraform.tfvars — listo
# =========================

# Región
location = "East US"

# Esquema de nombres (si vuelve a chocar, sube correlative: 94, 95…)
naming = {
  application_code = "INFR"
  objective_code   = "SVLS"
  environment      = "D"
  correlative      = "93"
}

# -------- Resource Group (usa el nombre de variable correcto) --------
rg_config = {
  tags = {
    Environment = "Development"
    Project     = "GEIA Example"
  }
  lock = null
}

# -------- Storage Account (usa stac_config) --------
stac_config = {
  # Permite claves durante el despliegue (backend/diag)
  enable_deployment_mode    = true
  shared_access_key_enabled = true

  # Etiquetas opcionales (si tu módulo las mergea)
  tags = {
    Environment = "Development"
  }

  # NO defino 'name'/'account_name' aquí a menos que tu módulo lo acepte.
  # Si tu módulo soporta override explícito y prefieres forzarlo, añade UNO:
  # name         = "staceu1infrsvlsd93jlm01"
  # account_name = "staceu1infrsvlsd93jlm01"
}

# -------- Log Analytics (usa law_config) --------
law_config = {
  # vacío → defaults del módulo
}

# -------- Key Vault (keyvault_config se mantiene igual) --------
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
    default_action = "Allow"   # Si cambias a "Deny", añade ip_rules/VNets
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }

  # Si tu módulo acepta 'name' y quieres forzarlo en lugar de depender de naming:
  # name = "azkveu1infrsvlsd93jlm01"
}
