# Multi-Backend Integration Tests
# Tests cross-backend identity functionality and consistency

variables {
  vault_address    = "http://localhost:8200"
  vault_token      = "root"
  test_entity_name = "bob"
}

# Test baseline multi-backend infrastructure
run "deploy_multi_backend_infrastructure" {
  command = apply

  assert {
    condition     = vault_ldap_auth_backend.ldap1.id != ""
    error_message = "LDAP1 backend should be created"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap2.id != ""
    error_message = "LDAP2 backend should be created"
  }

  assert {
    condition     = vault_identity_entity.bob.id != ""
    error_message = "Bob's identity entity should be created"
  }

  assert {
    condition     = vault_identity_entity_alias.ldap1_bob.id != ""
    error_message = "Bob's LDAP1 alias should be created"
  }

  assert {
    condition     = vault_identity_entity_alias.ldap2_bob.id != ""
    error_message = "Bob's LDAP2 alias should be created"
  }
}

# Test backend isolation and uniqueness
run "test_backend_isolation" {
  command = apply

  # Backends should have different paths
  assert {
    condition     = vault_ldap_auth_backend.ldap1.path != vault_ldap_auth_backend.ldap2.path
    error_message = "LDAP backends should have different mount paths"
  }

  # Backends should have different accessors
  assert {
    condition     = vault_ldap_auth_backend.ldap1.accessor != vault_ldap_auth_backend.ldap2.accessor
    error_message = "LDAP backends should have different accessors"
  }

  # But same configuration otherwise
  assert {
    condition     = vault_ldap_auth_backend.ldap1.url == vault_ldap_auth_backend.ldap2.url
    error_message = "Both LDAP backends should point to the same LDAP server"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap1.userdn == vault_ldap_auth_backend.ldap2.userdn
    error_message = "Both LDAP backends should use the same user DN"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap1.groupdn == vault_ldap_auth_backend.ldap2.groupdn
    error_message = "Both LDAP backends should use the same group DN"
  }
}

# Test cross-backend identity entity consistency
run "test_cross_backend_entity_consistency" {
  command = apply

  # Both aliases should reference the same entity
  assert {
    condition     = vault_identity_entity_alias.ldap1_bob.canonical_id == vault_identity_entity_alias.ldap2_bob.canonical_id
    error_message = "Bob's aliases across both LDAP backends should reference the same entity"
  }

  # Entity should be correctly configured
  assert {
    condition     = vault_identity_entity.bob.name == var.test_entity_name
    error_message = "Entity name should be 'bob'"
  }

  assert {
    condition     = vault_identity_entity.bob.metadata.organization == "example inc"
    error_message = "Entity should have correct organization metadata"
  }

  assert {
    condition     = vault_identity_entity.bob.metadata.dept == "platform team"
    error_message = "Entity should have correct department metadata"
  }
}

# Test cross-backend group mapping consistency
run "test_cross_backend_group_mapping" {
  command = apply

  # Vault-admins groups should exist for both backends
  assert {
    condition     = vault_identity_group.ldap1_vault_admins.id != ""
    error_message = "LDAP1 vault-admins group should exist"
  }

  assert {
    condition     = vault_identity_group.ldap2_vault_admins.id != ""
    error_message = "LDAP2 vault-admins group should exist"
  }

  # Developers groups should exist for both backends
  assert {
    condition     = vault_identity_group.ldap1_developers.id != ""
    error_message = "LDAP1 developers group should exist"
  }

  assert {
    condition     = vault_identity_group.ldap2_developers.id != ""
    error_message = "LDAP2 developers group should exist"
  }

  # Groups should have the same policies across backends
  assert {
    condition     = contains(vault_identity_group.ldap1_vault_admins.policies, "vault-admins") && contains(vault_identity_group.ldap2_vault_admins.policies, "vault-admins")
    error_message = "Vault-admins groups should have the same policies across backends"
  }

  assert {
    condition     = contains(vault_identity_group.ldap1_developers.policies, "app-secrets") && contains(vault_identity_group.ldap2_developers.policies, "app-secrets")
    error_message = "Developers groups should have the same policies across backends"
  }
}

# Test group alias consistency across backends
run "test_group_alias_consistency" {
  command = apply

  # Vault-admins aliases should have the same name across backends
  assert {
    condition     = vault_identity_group_alias.ldap1_vault_admins_alias.name == vault_identity_group_alias.ldap2_vault_admins_alias.name
    error_message = "Vault-admins group aliases should have the same name across backends"
  }

  assert {
    condition     = vault_identity_group_alias.ldap1_vault_admins_alias.name == "vault-admins"
    error_message = "Vault-admins group aliases should be named 'vault-admins'"
  }

  # Developers aliases should have the same name across backends
  assert {
    condition     = vault_identity_group_alias.ldap1_developers_alias.name == vault_identity_group_alias.ldap2_developers_alias.name
    error_message = "Developers group aliases should have the same name across backends"
  }

  assert {
    condition     = vault_identity_group_alias.ldap1_developers_alias.name == "developers"
    error_message = "Developers group aliases should be named 'developers'"
  }

  # Aliases should reference different group IDs (backend-specific groups)
  assert {
    condition     = vault_identity_group_alias.ldap1_vault_admins_alias.canonical_id != vault_identity_group_alias.ldap2_vault_admins_alias.canonical_id
    error_message = "Group aliases should reference different backend-specific group IDs"
  }

  assert {
    condition     = vault_identity_group_alias.ldap1_developers_alias.canonical_id != vault_identity_group_alias.ldap2_developers_alias.canonical_id
    error_message = "Developer group aliases should reference different backend-specific group IDs"
  }
}

# Test mount accessor consistency in aliases
run "test_mount_accessor_consistency" {
  command = apply

  # Entity aliases should reference correct mount accessors
  assert {
    condition     = vault_identity_entity_alias.ldap1_bob.mount_accessor == vault_ldap_auth_backend.ldap1.accessor
    error_message = "Bob's LDAP1 alias should reference LDAP1 backend accessor"
  }

  assert {
    condition     = vault_identity_entity_alias.ldap2_bob.mount_accessor == vault_ldap_auth_backend.ldap2.accessor
    error_message = "Bob's LDAP2 alias should reference LDAP2 backend accessor"
  }

  # Group aliases should reference correct mount accessors
  assert {
    condition     = vault_identity_group_alias.ldap1_vault_admins_alias.mount_accessor == vault_ldap_auth_backend.ldap1.accessor
    error_message = "LDAP1 vault-admins alias should reference LDAP1 backend accessor"
  }

  assert {
    condition     = vault_identity_group_alias.ldap2_vault_admins_alias.mount_accessor == vault_ldap_auth_backend.ldap2.accessor
    error_message = "LDAP2 vault-admins alias should reference LDAP2 backend accessor"
  }

  assert {
    condition     = vault_identity_group_alias.ldap1_developers_alias.mount_accessor == vault_ldap_auth_backend.ldap1.accessor
    error_message = "LDAP1 developers alias should reference LDAP1 backend accessor"
  }

  assert {
    condition     = vault_identity_group_alias.ldap2_developers_alias.mount_accessor == vault_ldap_auth_backend.ldap2.accessor
    error_message = "LDAP2 developers alias should reference LDAP2 backend accessor"
  }
}

# Test multi-backend authentication scenario simulation
run "test_multi_backend_auth_scenario" {
  command = apply

  # Ensure Bob can theoretically authenticate via either backend (entity exists)
  assert {
    condition     = vault_identity_entity_alias.ldap1_bob.name == var.test_entity_name
    error_message = "Bob should be able to authenticate via LDAP1 backend"
  }

  assert {
    condition     = vault_identity_entity_alias.ldap2_bob.name == var.test_entity_name
    error_message = "Bob should be able to authenticate via LDAP2 backend"
  }

  # Both aliases should maintain the same username
  assert {
    condition     = vault_identity_entity_alias.ldap1_bob.name == vault_identity_entity_alias.ldap2_bob.name
    error_message = "Bob's username should be the same across both LDAP backends"
  }
}

# Test policy inheritance through multi-backend groups
run "test_policy_inheritance_multi_backend" {
  command = apply

  # Verify all groups have appropriate policies
  assert {
    condition     = length(vault_identity_group.ldap1_vault_admins.policies) > 0
    error_message = "LDAP1 vault-admins group should have at least one policy"
  }

  assert {
    condition     = length(vault_identity_group.ldap2_vault_admins.policies) > 0
    error_message = "LDAP2 vault-admins group should have at least one policy"
  }

  assert {
    condition     = length(vault_identity_group.ldap1_developers.policies) > 0
    error_message = "LDAP1 developers group should have at least one policy"
  }

  assert {
    condition     = length(vault_identity_group.ldap2_developers.policies) > 0
    error_message = "LDAP2 developers group should have at least one policy"
  }

  # Verify policy consistency
  assert {
    condition     = contains(vault_identity_group.ldap1_vault_admins.policies, "vault-admins")
    error_message = "LDAP1 vault-admins group should contain vault-admins policy"
  }

  assert {
    condition     = contains(vault_identity_group.ldap2_vault_admins.policies, "vault-admins")
    error_message = "LDAP2 vault-admins group should contain vault-admins policy"
  }

  assert {
    condition     = contains(vault_identity_group.ldap1_developers.policies, "app-secrets")
    error_message = "LDAP1 developers group should contain app-secrets policy"
  }

  assert {
    condition     = contains(vault_identity_group.ldap2_developers.policies, "app-secrets")
    error_message = "LDAP2 developers group should contain app-secrets policy"
  }
}