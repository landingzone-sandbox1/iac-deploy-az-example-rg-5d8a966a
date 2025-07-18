locals {
  merged_naming = merge(var.naming, var.naming_override)
}