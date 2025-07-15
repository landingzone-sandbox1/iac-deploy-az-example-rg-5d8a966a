terraform {
  required_version = "~> 1.9"
  # backend "azurerm" {
  # use_azuread_auth     = true
  # }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.28"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = false
    }
  }
  storage_use_azuread          = true
  disable_terraform_partner_id = false
}

module "azure_rg_example" {
  # Use this source for local development:
  # source = "./module-source/iac-mod-az-resource-group"
  # For production, use:
  # tflint-ignore: terraform_module_pinned_source
  source = "git::ssh://git@github.com/landingzone-sandbox/iac-mod-az-resource-group.git?ref=rg-2025-07-11-1"

  # Pass-through variables directly to the child module
  location              = var.location
  naming                = local.merged_naming
  resource_group_config = var.rg_config

  # Storage config passed directly (naming is passed separately)
  storage_config = var.stac_config

  # Log analytics config passed directly 
  log_analytics_config = var.law_config

  # Key vault settings passed directly
  keyvault_config = var.keyvault_config
}
