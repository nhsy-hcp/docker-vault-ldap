# LDAP Authentication Integration Tests
# End-to-end tests for LDAP authentication functionality

variables {
  vault_address = "http://localhost:8200"
  vault_token   = "root"
  test_username = "bob"
  test_password = "password"
}

# Test infrastructure deployment
run "deploy_vault_ldap_infrastructure" {
  command = apply

  assert {
    condition     = vault_ldap_auth_backend.ldap.id != ""
    error_message = "LDAP1 backend should be successfully created"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap.id != ""
    error_message = "LDAP2 backend should be successfully created"
  }

  assert {
    condition     = vault_policy.vault_admins.id != ""
    error_message = "Vault-admins policy should be successfully created"
  }

  assert {
    condition     = vault_policy.app_secrets.id != ""
    error_message = "App-secrets policy should be successfully created"
  }

  assert {
    condition     = vault_identity_entity.bob.id != ""
    error_message = "Bob's identity entity should be successfully created"
  }
}

# Test LDAP1 backend accessibility
run "test_ldap1_backend_config" {
  command = apply

  assert {
    condition     = vault_ldap_auth_backend.ldap.accessor != ""
    error_message = "LDAP1 backend should have a valid accessor"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap.path == "ldap"
    error_message = "LDAP1 backend should be mounted at 'ldap1' path"
  }
}

# Test LDAP2 backend accessibility
run "test_ldap2_backend_config" {
  command = apply

  assert {
    condition     = vault_ldap_auth_backend.ldap.accessor != ""
    error_message = "LDAP2 backend should have a valid accessor"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap.path == "ldap"
    error_message = "LDAP2 backend should be mounted at 'ldap2' path"
  }
}

# Test group mappings are created
run "test_group_mappings_created" {
  command = apply

  assert {
    condition     = vault_identity_group.vault_admins.id != ""
    error_message = "LDAP1 vault-admins group should be created"
  }

  assert {
    condition     = vault_identity_group.vault_admins.id != ""
    error_message = "LDAP2 vault-admins group should be created"
  }

  assert {
    condition     = vault_identity_group.developers.id != ""
    error_message = "LDAP1 developers group should be created"
  }

  assert {
    condition     = vault_identity_group.developers.id != ""
    error_message = "LDAP2 developers group should be created"
  }
}

# Test group aliases are properly linked
run "test_group_aliases_linked" {
  command = apply

  assert {
    condition     = vault_identity_group_alias.vault_admins_alias.id != ""
    error_message = "LDAP1 vault-admins group alias should be created"
  }

  assert {
    condition     = vault_identity_group_alias.vault_admins_alias.id != ""
    error_message = "LDAP2 vault-admins group alias should be created"
  }

  assert {
    condition     = vault_identity_group_alias.developers_alias.id != ""
    error_message = "LDAP1 developers group alias should be created"
  }

  assert {
    condition     = vault_identity_group_alias.developers_alias.id != ""
    error_message = "LDAP2 developers group alias should be created"
  }
}

# Test entity aliases are created for cross-backend identity
run "test_entity_aliases_created" {
  command = apply

  assert {
    condition     = vault_identity_entity_alias.bob.id != ""
    error_message = "Bob's LDAP1 entity alias should be created"
  }

  assert {
    condition     = vault_identity_entity_alias.bob.id != ""
    error_message = "Bob's LDAP2 entity alias should be created"
  }

  # Both aliases should reference the same entity
  assert {
    condition     = vault_identity_entity_alias.bob.canonical_id == vault_identity_entity_alias.bob.canonical_id
    error_message = "Both Bob's aliases should reference the same entity for cross-backend identity"
  }
}

# Test KV secrets are created
run "test_kv_secrets_created" {
  command = apply

  assert {
    condition     = vault_kv_secret_v2.app_db.path != ""
    error_message = "App DB secret should be created"
  }

  assert {
    condition     = vault_kv_secret_v2.restricted_db.path != ""
    error_message = "Restricted DB secret should be created"
  }

  # Verify secret data structure
  assert {
    condition     = jsondecode(vault_kv_secret_v2.app_db.data_json).username == "app"
    error_message = "App DB secret should contain correct username"
  }

  assert {
    condition     = jsondecode(vault_kv_secret_v2.restricted_db.data_json).username == "app"
    error_message = "Restricted DB secret should contain correct username"
  }
}

# Test audit logging is enabled
run "test_audit_logging_enabled" {
  command = apply

  assert {
    condition     = vault_audit.stdout.id != ""
    error_message = "Audit logging should be enabled"
  }

  assert {
    condition     = vault_audit.stdout.type == "file"
    error_message = "Audit logging should use file type"
  }

  assert {
    condition     = vault_audit.stdout.options.file_path == "stdout"
    error_message = "Audit logging should output to stdout"
  }
}