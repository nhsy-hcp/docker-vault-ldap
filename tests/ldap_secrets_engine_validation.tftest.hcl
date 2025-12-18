# LDAP Secrets Engine Validation Tests
# Tests LDAP secrets engine configuration, static roles, and dynamic roles

variables {
  vault_address = "http://localhost:8200"
  vault_token   = "root"
}

# Test LDAP secrets backend configuration
run "validate_ldap_secrets_backend_config" {
  command = plan

  assert {
    condition     = vault_ldap_secret_backend.config.binddn == "cn=admin,dc=example,dc=com"
    error_message = "LDAP secrets backend should use correct bind DN"
  }

  assert {
    condition     = vault_ldap_secret_backend.config.url == "ldap://ldap:389"
    error_message = "LDAP secrets backend should use correct LDAP URL"
  }

  assert {
    condition     = vault_ldap_secret_backend.config.insecure_tls == true
    error_message = "LDAP secrets backend should have insecure_tls enabled for dev environment"
  }

  assert {
    condition     = vault_ldap_secret_backend.config.skip_static_role_import_rotation == true
    error_message = "LDAP secrets backend should skip import rotation for initial setup"
  }
}

# Test static role configuration for alice
run "validate_alice_static_role_config" {
  command = plan

  assert {
    condition     = vault_ldap_secret_backend_static_role.alice_static.username == "alice"
    error_message = "Alice static role should have correct username"
  }

  assert {
    condition     = vault_ldap_secret_backend_static_role.alice_static.dn == "cn=alice,ou=users,dc=example,dc=com"
    error_message = "Alice static role should have correct DN"
  }

  assert {
    condition     = vault_ldap_secret_backend_static_role.alice_static.role_name == "alice"
    error_message = "Alice static role should have correct role name"
  }

  assert {
    condition     = vault_ldap_secret_backend_static_role.alice_static.rotation_period == 300
    error_message = "Alice static role should have 300 second (5 minute) rotation period"
  }

  assert {
    condition     = vault_ldap_secret_backend_static_role.alice_static.skip_import_rotation == true
    error_message = "Alice static role should skip import rotation"
  }

  assert {
    condition     = vault_ldap_secret_backend_static_role.alice_static.mount == vault_ldap_secret_backend.config.path
    error_message = "Alice static role should be mounted on correct backend path"
  }
}

# Test dynamic role configuration for developer
run "validate_developer_dynamic_role_config" {
  command = plan

  assert {
    condition     = vault_ldap_secret_backend_dynamic_role.developer_dynamic.role_name == "developer"
    error_message = "Developer dynamic role should have correct role name"
  }

  assert {
    condition     = vault_ldap_secret_backend_dynamic_role.developer_dynamic.username_template == "{{.RoleName}}_{{random 10}}"
    error_message = "Developer dynamic role should have correct username template"
  }

  assert {
    condition     = vault_ldap_secret_backend_dynamic_role.developer_dynamic.mount == vault_ldap_secret_backend.config.path
    error_message = "Developer dynamic role should be mounted on correct backend path"
  }

  assert {
    condition     = length(vault_ldap_secret_backend_dynamic_role.developer_dynamic.creation_ldif) > 0
    error_message = "Developer dynamic role should have creation LDIF defined"
  }

  assert {
    condition     = length(vault_ldap_secret_backend_dynamic_role.developer_dynamic.deletion_ldif) > 0
    error_message = "Developer dynamic role should have deletion LDIF defined"
  }

  assert {
    condition     = length(vault_ldap_secret_backend_dynamic_role.developer_dynamic.rollback_ldif) > 0
    error_message = "Developer dynamic role should have rollback LDIF defined"
  }
}

# Test dynamic role LDIF content structure
run "validate_developer_dynamic_role_ldif" {
  command = plan

  assert {
    condition     = can(regex("dn: cn={{.Username}},ou=users,dc=example,dc=com", vault_ldap_secret_backend_dynamic_role.developer_dynamic.creation_ldif))
    error_message = "Creation LDIF should contain correct user DN pattern"
  }

  assert {
    condition     = can(regex("objectClass: person", vault_ldap_secret_backend_dynamic_role.developer_dynamic.creation_ldif))
    error_message = "Creation LDIF should define person object class"
  }

  assert {
    condition     = can(regex("dn: cn=developers,ou=groups,dc=example,dc=com", vault_ldap_secret_backend_dynamic_role.developer_dynamic.creation_ldif))
    error_message = "Creation LDIF should add user to developers group"
  }

  assert {
    condition     = can(regex("changetype: modify", vault_ldap_secret_backend_dynamic_role.developer_dynamic.creation_ldif))
    error_message = "Creation LDIF should modify developers group"
  }
}

# Integration test: Deploy LDAP secrets backend
run "deploy_ldap_secrets_backend" {
  command = apply

  assert {
    condition     = vault_ldap_secret_backend.config.id != ""
    error_message = "LDAP secrets backend should be successfully created"
  }

  assert {
    condition     = vault_ldap_secret_backend.config.path != ""
    error_message = "LDAP secrets backend should have a valid mount path"
  }

  assert {
    condition     = vault_ldap_secret_backend.config.accessor != ""
    error_message = "LDAP secrets backend should have a valid accessor"
  }
}

# Integration test: Deploy alice static role
run "deploy_alice_static_role" {
  command = apply

  assert {
    condition     = vault_ldap_secret_backend_static_role.alice_static.id != ""
    error_message = "Alice static role should be successfully created"
  }

  assert {
    condition     = vault_ldap_secret_backend_static_role.alice_static.mount == vault_ldap_secret_backend.config.path
    error_message = "Alice static role should reference correct backend mount"
  }
}

# Integration test: Deploy developer dynamic role
run "deploy_developer_dynamic_role" {
  command = apply

  assert {
    condition     = vault_ldap_secret_backend_dynamic_role.developer_dynamic.id != ""
    error_message = "Developer dynamic role should be successfully created"
  }

  assert {
    condition     = vault_ldap_secret_backend_dynamic_role.developer_dynamic.mount == vault_ldap_secret_backend.config.path
    error_message = "Developer dynamic role should reference correct backend mount"
  }
}

# Integration test: Verify backend configuration is applied
run "verify_ldap_secrets_backend_applied" {
  command = apply

  assert {
    condition     = vault_ldap_secret_backend.config.binddn == "cn=admin,dc=example,dc=com"
    error_message = "Applied backend should have correct bind DN"
  }

  assert {
    condition     = vault_ldap_secret_backend.config.url == "ldap://ldap:389"
    error_message = "Applied backend should have correct LDAP URL"
  }
}

# Integration test: Verify roles reference correct backend
run "verify_roles_backend_dependency" {
  command = apply

  assert {
    condition     = vault_ldap_secret_backend_static_role.alice_static.mount == vault_ldap_secret_backend.config.path
    error_message = "Static role should depend on backend mount path"
  }

  assert {
    condition     = vault_ldap_secret_backend_dynamic_role.developer_dynamic.mount == vault_ldap_secret_backend.config.path
    error_message = "Dynamic role should depend on backend mount path"
  }

  # Verify both roles exist on same backend
  assert {
    condition     = vault_ldap_secret_backend_static_role.alice_static.mount == vault_ldap_secret_backend_dynamic_role.developer_dynamic.mount
    error_message = "Both static and dynamic roles should be on the same backend mount"
  }
}