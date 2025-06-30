# Secrets Access Integration Tests
# Tests policy enforcement and secret access patterns

variables {
  vault_address = "http://localhost:8200"
  vault_token   = "root"
}

# Test baseline infrastructure deployment
run "deploy_infrastructure_for_secrets_testing" {
  command = apply

  assert {
    condition     = vault_kv_secret_v2.app_db.path != ""
    error_message = "App DB secret should be created"
  }

  assert {
    condition     = vault_kv_secret_v2.restricted_db.path != ""
    error_message = "Restricted DB secret should be created"
  }

  assert {
    condition     = vault_policy.vault_admins.id != ""
    error_message = "Vault-admins policy should be created"
  }

  assert {
    condition     = vault_policy.app_secrets.id != ""
    error_message = "App-secrets policy should be created"
  }
}

# Test secret data integrity
run "test_secret_data_integrity" {
  command = apply

  # Test app/db secret structure
  assert {
    condition     = jsondecode(vault_kv_secret_v2.app_db.data_json).username == "app"
    error_message = "App DB secret should contain username 'app'"
  }

  assert {
    condition     = jsondecode(vault_kv_secret_v2.app_db.data_json).password == "w1bble"
    error_message = "App DB secret should contain expected password"
  }

  # Test restricted/db secret structure
  assert {
    condition     = jsondecode(vault_kv_secret_v2.restricted_db.data_json).username == "app"
    error_message = "Restricted DB secret should contain username 'app'"
  }

  assert {
    condition     = jsondecode(vault_kv_secret_v2.restricted_db.data_json).password == "w1bble"
    error_message = "Restricted DB secret should contain expected password"
  }
}

# Test secret paths and mount points
run "test_secret_paths_and_mounts" {
  command = apply

  assert {
    condition     = vault_kv_secret_v2.app_db.mount == "secret"
    error_message = "App DB secret should use 'secret' mount"
  }

  assert {
    condition     = vault_kv_secret_v2.app_db.name == "app/db"
    error_message = "App DB secret should be at path 'app/db'"
  }

  assert {
    condition     = vault_kv_secret_v2.restricted_db.mount == "secret"
    error_message = "Restricted DB secret should use 'secret' mount"
  }

  assert {
    condition     = vault_kv_secret_v2.restricted_db.name == "restricted/db"
    error_message = "Restricted DB secret should be at path 'restricted/db'"
  }
}

# Test vault-admins policy can access all secrets
run "test_vault_admins_policy_access" {
  command = apply

  # Vault-admins policy should contain secret/* access
  assert {
    condition     = length(regexall("secret/\\*", vault_policy.vault_admins.policy)) > 0
    error_message = "Vault-admins policy should contain secret/* path for full access"
  }

  # Should have full CRUD capabilities
  assert {
    condition     = length(regexall("create.*read.*update.*delete.*list", vault_policy.vault_admins.policy)) > 0
    error_message = "Vault-admins policy should have full CRUD capabilities"
  }
}

# Test app-secrets policy restricted access
run "test_app_secrets_policy_restrictions" {
  command = apply

  # App-secrets policy should only contain app/* access
  assert {
    condition     = length(regexall("secret/data/app/\\*", vault_policy.app_secrets.policy)) > 0
    error_message = "App-secrets policy should contain secret/data/app/* path"
  }

  assert {
    condition     = length(regexall("secret/metadata/app/\\*", vault_policy.app_secrets.policy)) > 0
    error_message = "App-secrets policy should contain secret/metadata/app/* path"
  }

  # Should NOT contain restricted/* access
  assert {
    condition     = length(regexall("secret/data/restricted", vault_policy.app_secrets.policy)) == 0
    error_message = "App-secrets policy should NOT contain restricted path access"
  }

  assert {
    condition     = length(regexall("secret/metadata/restricted", vault_policy.app_secrets.policy)) == 0
    error_message = "App-secrets policy should NOT contain restricted metadata access"
  }
}

# Test policy assignments to identity groups
run "test_policy_assignments_to_groups" {
  command = apply

  # Vault-admins groups should have vault-admins policy
  assert {
    condition     = contains(vault_identity_group.ldap1_vault_admins.policies, vault_policy.vault_admins.name)
    error_message = "LDAP1 vault-admins group should have vault-admins policy"
  }

  assert {
    condition     = contains(vault_identity_group.ldap2_vault_admins.policies, vault_policy.vault_admins.name)
    error_message = "LDAP2 vault-admins group should have vault-admins policy"
  }

  # Developers groups should have app-secrets policy
  assert {
    condition     = contains(vault_identity_group.ldap1_developers.policies, vault_policy.app_secrets.name)
    error_message = "LDAP1 developers group should have app-secrets policy"
  }

  assert {
    condition     = contains(vault_identity_group.ldap2_developers.policies, vault_policy.app_secrets.name)
    error_message = "LDAP2 developers group should have app-secrets policy"
  }
}

# Test secret versioning and KV v2 features
run "test_kv_v2_features" {
  command = apply

  # Both secrets should be KV v2 format
  assert {
    condition     = vault_kv_secret_v2.app_db.path != ""
    error_message = "App DB secret should be created as KV v2"
  }

  assert {
    condition     = vault_kv_secret_v2.restricted_db.path != ""
    error_message = "Restricted DB secret should be created as KV v2"
  }

  # Secrets should have JSON data format
  assert {
    condition     = can(jsondecode(vault_kv_secret_v2.app_db.data_json))
    error_message = "App DB secret should have valid JSON data"
  }

  assert {
    condition     = can(jsondecode(vault_kv_secret_v2.restricted_db.data_json))
    error_message = "Restricted DB secret should have valid JSON data"
  }
}

# Test access control separation
run "test_access_control_separation" {
  command = apply

  # Ensure policies are distinct
  assert {
    condition     = vault_policy.vault_admins.policy != vault_policy.app_secrets.policy
    error_message = "Vault-admins and app-secrets policies should be different"
  }

  # Ensure different groups exist for different access levels
  assert {
    condition     = vault_identity_group.ldap1_vault_admins.name != vault_identity_group.ldap1_developers.name
    error_message = "Vault-admins and developers groups should be separate"
  }

  # Ensure policy assignments are distinct
  assert {
    condition     = !contains(vault_identity_group.ldap1_developers.policies, vault_policy.vault_admins.name)
    error_message = "Developers group should not have vault-admins policy"
  }

  assert {
    condition     = !contains(vault_identity_group.ldap1_vault_admins.policies, vault_policy.app_secrets.name)
    error_message = "Vault-admins group should not need app-secrets policy (has broader access)"
  }
}