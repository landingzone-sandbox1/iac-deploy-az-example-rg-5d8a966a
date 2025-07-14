# Naming configuration for certification environment
naming = {
  environment      = "C"     # Certification environment
  correlative      = "55"    # Certification correlative number
  objective_code   = "INFR"  # Infrastructure objective code
}

# Resource Group configuration for certification environment
rg_config = {
  tags = {
    Environment = "Certification"
    Purpose     = "Infrastructure"
  }
  lock = {
    kind = "ReadOnly"  # Read-only lock for certification environment
    name = "certification-lock"
  }
}