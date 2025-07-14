# Naming configuration for production environment
naming = {
  environment      = "P"     # Production environment
  correlative      = "65"    # Production correlative number
  objective_code   = "INFR"  # Infrastructure objective code
}

# Resource Group configuration for production environment
rg_config = {
  tags = {
    Environment = "Production"
    Purpose     = "Infrastructure"
  }
  lock = {
    kind = "CanNotDelete"  # Lock production resources to prevent accidental deletion
    name = "production-lock"
  }
}