# Outputs for test setup helper module

output "test_prefix" {
  description = "Unique test prefix for resource isolation"
  value       = local.test_prefix
}

output "vault_address" {
  description = "Vault server address"
  value       = local.vault_address
}

output "vault_token" {
  description = "Vault authentication token"
  value       = local.vault_token
  sensitive   = true
}

output "ldap_server_url" {
  description = "LDAP server URL"
  value       = local.ldap_server_url
}

output "ldap_admin_dn" {
  description = "LDAP admin bind DN"
  value       = local.ldap_admin_dn
}

output "ldap_admin_password" {
  description = "LDAP admin password"
  value       = local.ldap_admin_password
  sensitive   = true
}

output "test_username" {
  description = "Test username for LDAP authentication"
  value       = var.test_username
}

output "test_password" {
  description = "Test password for LDAP authentication"
  value       = var.test_password
  sensitive   = true
}

output "expected_userdn" {
  description = "Expected LDAP user DN"
  value       = "ou=users,dc=example,dc=com"
}

output "expected_groupdn" {
  description = "Expected LDAP group DN"
  value       = "ou=groups,dc=example,dc=com"
}

output "vault_admins_policy_name" {
  description = "Vault admins policy name"
  value       = "vault-admins"
}

output "app_secrets_policy_name" {
  description = "App secrets policy name"
  value       = "app-secrets"
}

output "ldap_backend_path" {
  description = "LDAP backend mount path"
  value       = "ldap"
}