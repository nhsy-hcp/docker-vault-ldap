# Variables for test setup helper module

variable "vault_address" {
  description = "Vault server address"
  type        = string
  default     = "http://localhost:8200"
}

variable "vault_token" {
  description = "Vault authentication token"
  type        = string
  default     = "root"
  sensitive   = true
}

variable "ldap_server_url" {
  description = "LDAP server URL"
  type        = string
  default     = "ldap://ldap:389"
}

variable "ldap_admin_dn" {
  description = "LDAP admin bind DN"
  type        = string
  default     = "cn=admin,dc=example,dc=com"
}

variable "ldap_admin_password" {
  description = "LDAP admin password"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "test_username" {
  description = "Test username for LDAP authentication"
  type        = string
  default     = "bob"
}

variable "test_password" {
  description = "Test password for LDAP authentication"
  type        = string
  default     = "password"
  sensitive   = true
}