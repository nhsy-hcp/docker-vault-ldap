# Configure the Vault provider
terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
    }
  }
}

provider "vault" {
  # address = "http://localhost:8200" # VAULT_ADDR
  # token   = "root"                  # VAULT_TOKEN
  skip_child_token = true
}

# Enable audit log (stdout in this case)
resource "vault_audit" "stdout" {
  type = "file"
  options = {
    file_path = "stdout"
  }
}

# Enable and configure LDAP authentication backend 1
resource "vault_ldap_auth_backend" "ldap1" {
  path          = "ldap1"
  url           = "ldap://ldap:389"
  userdn        = "ou=users,dc=example,dc=com"
  userattr      = "cn"
  groupdn       = "ou=groups,dc=example,dc=com"
  groupfilter   = "(|(memberUid={{.Username}})(member={{.UserDN}}))"
  groupattr     = "cn"
  binddn        = "cn=admin,dc=example,dc=com"
  bindpass      = "admin"
  token_ttl     = 60 * 10
  token_max_ttl = 60 * 60 * 24
}

# Enable and configure LDAP authentication backend 2
resource "vault_ldap_auth_backend" "ldap2" {
  path          = "ldap2"
  url           = "ldap://ldap:389"
  userdn        = "ou=users,dc=example,dc=com"
  userattr      = "cn"
  groupdn       = "ou=groups,dc=example,dc=com"
  groupfilter   = "(|(memberUid={{.Username}})(member={{.UserDN}}))"
  groupattr     = "cn"
  binddn        = "cn=admin,dc=example,dc=com"
  bindpass      = "admin"
  token_ttl     = 60 * 10
  token_max_ttl = 60 * 60 * 24
}


# Create Vault policies
resource "vault_policy" "vault_admins" {
  name   = "vault-admins"
  policy = file("./files/vault-admins-policy.hcl")
}

resource "vault_policy" "app_secrets" {
  name   = "app-secrets"
  policy = file("./files/app-secrets-policy.hcl")
}

# Note: External groups can have one (and only one) alias
# https://developer.hashicorp.com/vault/docs/concepts/identity

# Create external groups and aliases for LDAP 1
resource "vault_identity_group" "ldap1_vault_admins" {
  name     = "ldap1-vault-admins"
  type     = "external"
  policies = [vault_policy.vault_admins.name]
}

# Create external groups and aliases for LDAP 2
resource "vault_identity_group" "ldap2_vault_admins" {
  name     = "ldap2-vault-admins"
  type     = "external"
  policies = [vault_policy.vault_admins.name]
}

resource "vault_identity_group_alias" "ldap1_vault_admins_alias" {
  name           = "vault-admins"
  canonical_id   = vault_identity_group.ldap1_vault_admins.id
  mount_accessor = vault_ldap_auth_backend.ldap1.accessor
}

resource "vault_identity_group_alias" "ldap2_vault_admins_alias" {
  name           = "vault-admins"
  canonical_id   = vault_identity_group.ldap2_vault_admins.id
  mount_accessor = vault_ldap_auth_backend.ldap2.accessor
}

resource "vault_identity_group" "ldap1_developers" {
  name     = "ldap1-developers"
  type     = "external"
  policies = [vault_policy.app_secrets.name]
}

resource "vault_identity_group" "ldap2_developers" {
  name     = "ldap2-developers"
  type     = "external"
  policies = [vault_policy.app_secrets.name]
}

resource "vault_identity_group_alias" "ldap1_developers_alias" {
  name           = "developers"
  canonical_id   = vault_identity_group.ldap1_developers.id
  mount_accessor = vault_ldap_auth_backend.ldap1.accessor
}

resource "vault_identity_group_alias" "ldap2_developers_alias" {
  name           = "developers"
  canonical_id   = vault_identity_group.ldap2_developers.id
  mount_accessor = vault_ldap_auth_backend.ldap2.accessor
}

# Create entity and aliases
resource "vault_identity_entity" "bob" {
  name = "bob"
  metadata = {
    organization = "example inc"
    dept         = "platform team"
  }
}

resource "vault_identity_entity_alias" "ldap1_bob" {
  name           = "bob"
  canonical_id   = vault_identity_entity.bob.id
  mount_accessor = vault_ldap_auth_backend.ldap1.accessor
}

resource "vault_identity_entity_alias" "ldap2_bob" {
  name           = "bob"
  canonical_id   = vault_identity_entity.bob.id
  mount_accessor = vault_ldap_auth_backend.ldap2.accessor
}

# Write KV secrets
resource "vault_kv_secret_v2" "app_db" {
  mount = "secret" # Default mount path for KV v2
  name  = "app/db"
  data_json = jsonencode({
    username = "app"
    password = "w1bble"
  })
}
resource "vault_kv_secret_v2" "restricted_db" {
  mount = "secret" # Default mount path for KV v2
  name  = "restricted/db"
  data_json = jsonencode({
    username = "app"
    password = "w1bble"
  })
}