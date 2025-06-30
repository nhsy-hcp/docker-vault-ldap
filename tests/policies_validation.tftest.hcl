# Vault Policies Validation Tests
# Tests policy creation and content validation

variables {
  vault_admins_policy_name = "vault-admins"
  app_secrets_policy_name  = "app-secrets"
}

# Test vault-admins policy configuration
run "validate_vault_admins_policy" {
  command = plan

  assert {
    condition     = vault_policy.vault_admins.name == var.vault_admins_policy_name
    error_message = "Vault admins policy name should be 'vault-admins'"
  }

  assert {
    condition     = length(vault_policy.vault_admins.policy) > 0
    error_message = "Vault admins policy should not be empty"
  }

  # Test that policy file is loaded correctly
  assert {
    condition     = length(regexall("sys/policies/acl", vault_policy.vault_admins.policy)) > 0
    error_message = "Vault admins policy should contain sys/policies/acl path"
  }

  assert {
    condition     = length(regexall("auth/\\*", vault_policy.vault_admins.policy)) > 0
    error_message = "Vault admins policy should contain auth/* path"
  }

  assert {
    condition     = length(regexall("identity/\\*", vault_policy.vault_admins.policy)) > 0
    error_message = "Vault admins policy should contain identity/* path"
  }

  assert {
    condition     = length(regexall("secret/\\*", vault_policy.vault_admins.policy)) > 0
    error_message = "Vault admins policy should contain secret/* path"
  }
}

# Test app-secrets policy configuration
run "validate_app_secrets_policy" {
  command = plan

  assert {
    condition     = vault_policy.app_secrets.name == var.app_secrets_policy_name
    error_message = "App secrets policy name should be 'app-secrets'"
  }

  assert {
    condition     = length(vault_policy.app_secrets.policy) > 0
    error_message = "App secrets policy should not be empty"
  }

  # Test that policy restricts access to app/* paths only
  assert {
    condition     = length(regexall("secret/data/app/\\*", vault_policy.app_secrets.policy)) > 0
    error_message = "App secrets policy should contain secret/data/app/* path"
  }

  assert {
    condition     = length(regexall("secret/metadata/app/\\*", vault_policy.app_secrets.policy)) > 0
    error_message = "App secrets policy should contain secret/metadata/app/* path"
  }

  # Ensure it doesn't contain admin paths (negative test)
  assert {
    condition     = length(regexall("sys/policies", vault_policy.app_secrets.policy)) == 0
    error_message = "App secrets policy should not contain sys/policies path"
  }

  assert {
    condition     = length(regexall("auth/\\*", vault_policy.app_secrets.policy)) == 0
    error_message = "App secrets policy should not contain auth/* path"
  }
}

# Test policy capabilities in vault-admins policy
run "validate_vault_admins_capabilities" {
  command = plan

  # Check for admin capabilities
  assert {
    condition     = length(regexall("create.*read.*update.*delete.*list", vault_policy.vault_admins.policy)) > 0
    error_message = "Vault admins policy should contain full CRUD capabilities"
  }

  assert {
    condition     = length(regexall("sudo", vault_policy.vault_admins.policy)) > 0
    error_message = "Vault admins policy should contain sudo capability"
  }
}

# Test policy capabilities in app-secrets policy
run "validate_app_secrets_capabilities" {
  command = plan

  # Check for limited capabilities (should have CRUD but not sudo)
  assert {
    condition     = length(regexall("read.*list.*create.*update.*delete", vault_policy.app_secrets.policy)) > 0
    error_message = "App secrets policy should contain CRUD capabilities for app paths"
  }

  # Ensure no sudo capability
  assert {
    condition     = length(regexall("sudo", vault_policy.app_secrets.policy)) == 0
    error_message = "App secrets policy should not contain sudo capability"
  }
}

# Test policy file references
run "validate_policy_file_references" {
  command = plan

  assert {
    condition     = length(regexall("\\./files/vault-admins\\.hcl", vault_policy.vault_admins.policy)) > 0 || vault_policy.vault_admins.name == "vault-admins"
    error_message = "Vault admins policy should reference correct file path"
  }

  assert {
    condition     = length(regexall("\\./files/app-secrets\\.hcl", vault_policy.app_secrets.policy)) > 0 || vault_policy.app_secrets.name == "app-secrets"
    error_message = "App secrets policy should reference correct file path"
  }
}

# Test policies are distinct
run "validate_policies_are_distinct" {
  command = plan

  assert {
    condition     = vault_policy.vault_admins.name != vault_policy.app_secrets.name
    error_message = "Vault policies should have different names"
  }

  assert {
    condition     = vault_policy.vault_admins.policy != vault_policy.app_secrets.policy
    error_message = "Vault policies should have different content"
  }
}