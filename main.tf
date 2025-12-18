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

# Enable and configure LDAP authentication backend
resource "vault_ldap_auth_backend" "ldap" {
  path          = "ldap"
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

# Create external groups and aliases for LDAP
resource "vault_identity_group" "vault_admins" {
  name     = "vault-admins"
  type     = "external"
  policies = [vault_policy.vault_admins.name]
}

resource "vault_identity_group_alias" "vault_admins_alias" {
  name           = "vault-admins"
  canonical_id   = vault_identity_group.vault_admins.id
  mount_accessor = vault_ldap_auth_backend.ldap.accessor
}

resource "vault_identity_group" "developers" {
  name     = "developers"
  type     = "external"
  policies = [vault_policy.app_secrets.name]
}

resource "vault_identity_group_alias" "developers_alias" {
  name           = "developers"
  canonical_id   = vault_identity_group.developers.id
  mount_accessor = vault_ldap_auth_backend.ldap.accessor
}

# Create entity and aliases
resource "vault_identity_entity" "bob" {
  name = "bob"
  metadata = {
    organization = "example inc"
    dept         = "platform team"
  }
}

resource "vault_identity_entity_alias" "bob" {
  name           = "bob"
  canonical_id   = vault_identity_entity.bob.id
  mount_accessor = vault_ldap_auth_backend.ldap.accessor
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

# Secret engine
resource "vault_ldap_secret_backend" "config" {
  binddn                           = "cn=admin,dc=example,dc=com"
  bindpass                         = "admin"
  url                              = "ldap://ldap:389"
  insecure_tls                     = "true"
  skip_static_role_import_rotation = true
}

resource "vault_ldap_secret_backend_static_role" "alice_static" {
  mount                = vault_ldap_secret_backend.config.path
  username             = "alice"
  dn                   = "cn=alice,ou=users,dc=example,dc=com"
  role_name            = "alice"
  rotation_period      = 300
  skip_import_rotation = true
}

resource "vault_ldap_secret_backend_dynamic_role" "developer_dynamic" {
  mount             = vault_ldap_secret_backend.config.path
  role_name         = "developer"
  username_template = "{{.RoleName}}_{{random 10}}"
  default_ttl       = 300
  max_ttl           = 300
  creation_ldif     = <<EOT
dn: cn={{.Username}},ou=users,dc=example,dc=com
changetype: add
objectClass: person
sn: {{random 20}}
cn: {{.Username}}

dn: cn=developers,ou=groups,dc=example,dc=com
changetype: modify
add: member
member: cn={{.Username}},ou=users,dc=example,dc=com
-
EOT
  deletion_ldif     = <<EOT
dn: cn={{.Username}},ou=users,dc=learn,dc=example
changetype: delete
EOT
  rollback_ldif     = <<EOT
dn: cn={{.Username}},ou=users,dc=learn,dc=example
changetype: delete
EOT
}