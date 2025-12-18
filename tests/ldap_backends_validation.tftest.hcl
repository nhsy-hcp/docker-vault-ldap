# LDAP Authentication Backend Validation Tests

variables {
  expected_ldap_url = "ldap://ldap:389"
  expected_userdn   = "ou=users,dc=example,dc=com"
  expected_groupdn  = "ou=groups,dc=example,dc=com"
  expected_binddn   = "cn=admin,dc=example,dc=com"
  expected_bindpass = "admin"
}

# Test LDAP backend configuration
run "validate_ldap_backend_config" {
  command = plan

  assert {
    condition     = vault_ldap_auth_backend.ldap.path == "ldap"
    error_message = "LDAP backend path should be 'ldap'"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap.url == var.expected_ldap_url
    error_message = "LDAP backend URL should be 'ldap://ldap:389'"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap.userdn == var.expected_userdn
    error_message = "LDAP backend userdn should be 'ou=users,dc=example,dc=com'"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap.userattr == "cn"
    error_message = "LDAP backend userattr should be 'cn'"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap.groupdn == var.expected_groupdn
    error_message = "LDAP backend groupdn should be 'ou=groups,dc=example,dc=com'"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap.groupfilter == "(|(memberUid={{.Username}})(member={{.UserDN}}))"
    error_message = "LDAP backend groupfilter is incorrect"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap.groupattr == "cn"
    error_message = "LDAP backend groupattr should be 'cn'"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap.binddn == var.expected_binddn
    error_message = "LDAP backend binddn should be 'cn=admin,dc=example,dc=com'"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap.bindpass == var.expected_bindpass
    error_message = "LDAP backend bindpass should be 'admin'"
  }
}

# Test token TTL configuration
run "validate_ldap_token_ttl_config" {
  command = plan

  assert {
    condition     = vault_ldap_auth_backend.ldap.token_ttl == 600
    error_message = "LDAP backend token_ttl should be 600 seconds (10 minutes)"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap.token_max_ttl == 86400
    error_message = "LDAP backend token_max_ttl should be 86400 seconds (24 hours)"
  }
}