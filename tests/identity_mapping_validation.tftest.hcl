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
    condition     = vault_identity_group.vault_admins.name == "vault-admins"
    error_message = "vault-admins group name should be 'vault-admins'"
  }

  assert {
    condition     = vault_identity_group.vault_admins.type == "external"
    error_message = "vault-admins group should be external type"
  }

  assert {
    condition     = vault_identity_group.developers.name == "developers"
    error_message = "developers group name should be 'developers'"
  }

  assert {
    condition     = vault_identity_group.developers.type == "external"
    error_message = "developers group should be external type"
  }
}

# Test group aliases configuration
run "validate_group_aliases_config" {
  command = plan

  assert {
    condition     = vault_identity_group_alias.vault_admins_alias.name == "vault-admins"
    error_message = "vault-admins alias name should be 'vault-admins'"
  }

  assert {
    condition     = vault_identity_group_alias.developers_alias.name == "developers"
    error_message = "developers alias name should be 'developers'"
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

# Test Bob's entity alias configuration
run "validate_bob_alias_config" {
  command = plan

  assert {
    condition     = vault_identity_entity_alias.bob.name == var.expected_bob_entity_name
    error_message = "Bob's alias name should be 'bob'"
  }
}