# Identity Mapping Validation Tests
# Tests identity groups, entities, and aliases configuration

variables {
  expected_bob_entity_name    = "bob"
  expected_vault_admins_group = "vault-admins"
  expected_developers_group   = "developers"
}

# Test identity groups configuration
run "validate_identity_groups_config" {
  command = plan

  assert {
    condition     = vault_identity_group.ldap1_vault_admins.name == "ldap1-vault-admins"
    error_message = "LDAP1 vault-admins group name should be 'ldap1-vault-admins'"
  }

  assert {
    condition     = vault_identity_group.ldap1_vault_admins.type == "external"
    error_message = "LDAP1 vault-admins group should be external type"
  }

  assert {
    condition     = vault_identity_group.ldap2_vault_admins.name == "ldap2-vault-admins"
    error_message = "LDAP2 vault-admins group name should be 'ldap2-vault-admins'"
  }

  assert {
    condition     = vault_identity_group.ldap2_vault_admins.type == "external"
    error_message = "LDAP2 vault-admins group should be external type"
  }
}

# Test developers groups configuration
run "validate_developers_groups_config" {
  command = plan

  assert {
    condition     = vault_identity_group.ldap1_developers.name == "ldap1-developers"
    error_message = "LDAP1 developers group name should be 'ldap1-developers'"
  }

  assert {
    condition     = vault_identity_group.ldap1_developers.type == "external"
    error_message = "LDAP1 developers group should be external type"
  }

  assert {
    condition     = vault_identity_group.ldap2_developers.name == "ldap2-developers"
    error_message = "LDAP2 developers group name should be 'ldap2-developers'"
  }

  assert {
    condition     = vault_identity_group.ldap2_developers.type == "external"
    error_message = "LDAP2 developers group should be external type"
  }
}

# Test group aliases configuration
run "validate_group_aliases_config" {
  command = plan

  assert {
    condition     = vault_identity_group_alias.ldap1_vault_admins_alias.name == "vault-admins"
    error_message = "LDAP1 vault-admins alias name should be 'vault-admins'"
  }

  assert {
    condition     = vault_identity_group_alias.ldap2_vault_admins_alias.name == "vault-admins"
    error_message = "LDAP2 vault-admins alias name should be 'vault-admins'"
  }

  assert {
    condition     = vault_identity_group_alias.ldap1_developers_alias.name == "developers"
    error_message = "LDAP1 developers alias name should be 'developers'"
  }

  assert {
    condition     = vault_identity_group_alias.ldap2_developers_alias.name == "developers"
    error_message = "LDAP2 developers alias name should be 'developers'"
  }
}

# Test Bob's identity entity configuration
run "validate_bob_entity_config" {
  command = plan

  assert {
    condition     = vault_identity_entity.bob.name == var.expected_bob_entity_name
    error_message = "Bob's entity name should be 'bob'"
  }

  assert {
    condition     = vault_identity_entity.bob.metadata.organization == "example inc"
    error_message = "Bob's entity should have organization metadata set to 'example inc'"
  }

  assert {
    condition     = vault_identity_entity.bob.metadata.dept == "platform team"
    error_message = "Bob's entity should have dept metadata set to 'platform team'"
  }
}

# Test Bob's entity aliases configuration
run "validate_bob_aliases_config" {
  command = plan

  assert {
    condition     = vault_identity_entity_alias.ldap1_bob.name == var.expected_bob_entity_name
    error_message = "Bob's LDAP1 alias name should be 'bob'"
  }

  assert {
    condition     = vault_identity_entity_alias.ldap2_bob.name == var.expected_bob_entity_name
    error_message = "Bob's LDAP2 alias name should be 'bob'"
  }
}