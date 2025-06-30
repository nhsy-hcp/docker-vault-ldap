# LDAP Authentication Backends Validation Tests
# Tests LDAP backend configuration for both ldap1 and ldap2

variables {
  expected_ldap_url = "ldap://ldap:389"
  expected_userdn   = "ou=users,dc=example,dc=com"
  expected_groupdn  = "ou=groups,dc=example,dc=com"
  expected_binddn   = "cn=admin,dc=example,dc=com"
  expected_bindpass = "admin"
}

# Test LDAP1 backend configuration
run "validate_ldap1_backend_config" {
  command = plan

  assert {
    condition     = vault_ldap_auth_backend.ldap1.path == "ldap1"
    error_message = "LDAP1 backend path should be 'ldap1'"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap1.url == var.expected_ldap_url
    error_message = "LDAP1 backend URL should be 'ldap://ldap:389'"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap1.userdn == var.expected_userdn
    error_message = "LDAP1 backend userdn should be 'ou=users,dc=example,dc=com'"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap1.userattr == "cn"
    error_message = "LDAP1 backend userattr should be 'cn'"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap1.groupdn == var.expected_groupdn
    error_message = "LDAP1 backend groupdn should be 'ou=groups,dc=example,dc=com'"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap1.groupfilter == "(|(memberUid={{.Username}})(member={{.UserDN}}))"
    error_message = "LDAP1 backend groupfilter is incorrect"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap1.groupattr == "cn"
    error_message = "LDAP1 backend groupattr should be 'cn'"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap1.binddn == var.expected_binddn
    error_message = "LDAP1 backend binddn should be 'cn=admin,dc=example,dc=com'"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap1.bindpass == var.expected_bindpass
    error_message = "LDAP1 backend bindpass should be 'admin'"
  }
}

# Test LDAP2 backend configuration
run "validate_ldap2_backend_config" {
  command = plan

  assert {
    condition     = vault_ldap_auth_backend.ldap2.path == "ldap2"
    error_message = "LDAP2 backend path should be 'ldap2'"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap2.url == var.expected_ldap_url
    error_message = "LDAP2 backend URL should be 'ldap://ldap:389'"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap2.userdn == var.expected_userdn
    error_message = "LDAP2 backend userdn should be 'ou=users,dc=example,dc=com'"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap2.userattr == "cn"
    error_message = "LDAP2 backend userattr should be 'cn'"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap2.groupdn == var.expected_groupdn
    error_message = "LDAP2 backend groupdn should be 'ou=groups,dc=example,dc=com'"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap2.groupfilter == "(|(memberUid={{.Username}})(member={{.UserDN}}))"
    error_message = "LDAP2 backend groupfilter is incorrect"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap2.groupattr == "cn"
    error_message = "LDAP2 backend groupattr should be 'cn'"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap2.binddn == var.expected_binddn
    error_message = "LDAP2 backend binddn should be 'cn=admin,dc=example,dc=com'"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap2.bindpass == var.expected_bindpass
    error_message = "LDAP2 backend bindpass should be 'admin'"
  }
}

# Test token TTL configuration
run "validate_ldap_token_ttl_config" {
  command = plan

  assert {
    condition     = vault_ldap_auth_backend.ldap1.token_ttl == 600
    error_message = "LDAP1 backend token_ttl should be 600 seconds (10 minutes)"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap1.token_max_ttl == 86400
    error_message = "LDAP1 backend token_max_ttl should be 86400 seconds (24 hours)"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap2.token_ttl == 600
    error_message = "LDAP2 backend token_ttl should be 600 seconds (10 minutes)"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap2.token_max_ttl == 86400
    error_message = "LDAP2 backend token_max_ttl should be 86400 seconds (24 hours)"
  }
}

# Test both backends have different paths but same configuration
run "validate_backends_consistency" {
  command = plan

  assert {
    condition     = vault_ldap_auth_backend.ldap1.path != vault_ldap_auth_backend.ldap2.path
    error_message = "LDAP backends should have different paths"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap1.url == vault_ldap_auth_backend.ldap2.url
    error_message = "Both LDAP backends should point to the same LDAP server"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap1.userdn == vault_ldap_auth_backend.ldap2.userdn
    error_message = "Both LDAP backends should use the same userdn"
  }

  assert {
    condition     = vault_ldap_auth_backend.ldap1.groupdn == vault_ldap_auth_backend.ldap2.groupdn
    error_message = "Both LDAP backends should use the same groupdn"
  }
}