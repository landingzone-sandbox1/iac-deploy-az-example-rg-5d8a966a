# Naming configuration for development environment
naming = {
  environment      = "D"     # Development environment
  correlative      = "95"    # Your custom correlative number
  objective_code   = "SEGU"  # Security objective code
}

# Resource Group configuration for development environment
rg_config = {
  tags = {
    Environment = "Development"
    Purpose     = "Infrastructure"
  }
  lock = null  # No lock for development environment
}