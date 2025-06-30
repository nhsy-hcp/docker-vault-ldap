# Vault Configuration Validation Tests
# Tests basic Vault provider configuration, audit settings, and resource attributes

variables {
  vault_dev_token = "root"
  vault_address   = "http://localhost:8200"
}

# Test Vault audit configuration
run "validate_audit_configuration" {
  command = plan

  assert {
    condition     = vault_audit.stdout.type == "file"
    error_message = "Audit type should be 'file'"
  }

  assert {
    condition     = vault_audit.stdout.options.file_path == "stdout"
    error_message = "Audit file path should be 'stdout'"
  }
}

# Test KV secrets configuration
run "validate_kv_secrets_structure" {
  command = plan

  assert {
    condition     = vault_kv_secret_v2.app_db.mount == "secret"
    error_message = "App DB secret should use 'secret' mount"
  }

  assert {
    condition     = vault_kv_secret_v2.app_db.name == "app/db"
    error_message = "App DB secret name should be 'app/db'"
  }

  assert {
    condition     = vault_kv_secret_v2.restricted_db.mount == "secret"
    error_message = "Restricted DB secret should use 'secret' mount"
  }

  assert {
    condition     = vault_kv_secret_v2.restricted_db.name == "restricted/db"
    error_message = "Restricted DB secret name should be 'restricted/db'"
  }
}

# Test secret data structure
run "validate_secret_data_content" {
  command = plan

  assert {
    condition     = jsondecode(vault_kv_secret_v2.app_db.data_json).username == "app"
    error_message = "App DB secret should contain username 'app'"
  }

  assert {
    condition     = jsondecode(vault_kv_secret_v2.app_db.data_json).password == "w1bble"
    error_message = "App DB secret should contain expected password"
  }

  assert {
    condition     = jsondecode(vault_kv_secret_v2.restricted_db.data_json).username == "app"
    error_message = "Restricted DB secret should contain username 'app'"
  }

  assert {
    condition     = jsondecode(vault_kv_secret_v2.restricted_db.data_json).password == "w1bble"
    error_message = "Restricted DB secret should contain expected password"
  }
}

# Test basic configuration validation
run "validate_resource_configuration" {
  command = plan

  assert {
    condition     = vault_audit.stdout.type == "file"
    error_message = "Audit should be configured with file type"
  }

  assert {
    condition     = vault_kv_secret_v2.app_db.mount == "secret"
    error_message = "Secrets should use correct mount point"
  }
}