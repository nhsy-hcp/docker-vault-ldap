# Test Setup Helper Module
# Provides common test environment variables and configurations

terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Generate a random test suffix for isolation
resource "random_id" "test_suffix" {
  byte_length = 4
}

# Test environment variables
locals {
  test_prefix         = "test-${random_id.test_suffix.hex}"
  vault_address       = var.vault_address
  vault_token         = var.vault_token
  ldap_server_url     = var.ldap_server_url
  ldap_admin_dn       = var.ldap_admin_dn
  ldap_admin_password = var.ldap_admin_password
}