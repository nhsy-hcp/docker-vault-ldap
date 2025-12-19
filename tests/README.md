# Terraform Tests for Vault LDAP Integration

This directory contains comprehensive Terraform tests for the Vault LDAP authentication integration using Terraform's native testing framework.

## Test Structure

### Unit Tests (Plan-based validation)
- **`vault_config_validation.tftest.hcl`** - Validates Vault provider configuration, audit settings, and basic resource attributes
- **`ldap_backends_validation.tftest.hcl`** - Tests LDAP authentication backend configuration
- **`policies_validation.tftest.hcl`** - Validates policy content and structure
- **`identity_mapping_validation.tftest.hcl`** - Tests identity groups, entities, and aliases configuration

### Integration Tests (Apply-based validation)
- **`ldap_auth_integration.tftest.hcl`** - End-to-end LDAP authentication testing
- **`secrets_access_integration.tftest.hcl`** - Tests secret access patterns and policy enforcement
- **`multi_backend_integration.tftest.hcl`** - Validates cross-backend identity entity functionality

### Helper Modules
- **`setup/`** - Helper module for test environment preparation with common variables and configurations

## Prerequisites

1. **Terraform 1.6.0+** - Required for native testing framework
2. **Running Vault and LDAP services** - Use `task all` to start the stack
3. **Vault environment variables**:
   ```bash
   export VAULT_ADDR=http://localhost:8200
   export VAULT_TOKEN=root
   ```

## Running Tests

### Run Unit Tests (Recommended)
Fast configuration validation tests that don't modify infrastructure:
```bash
# Run all unit tests
terraform test -filter=tests/vault_config_validation.tftest.hcl -filter=tests/ldap_backends_validation.tftest.hcl -filter=tests/policies_validation.tftest.hcl -filter=tests/identity_mapping_validation.tftest.hcl

# Run individual unit tests
terraform test -filter=tests/vault_config_validation.tftest.hcl
terraform test -filter=tests/ldap_backends_validation.tftest.hcl
terraform test -filter=tests/policies_validation.tftest.hcl
terraform test -filter=tests/identity_mapping_validation.tftest.hcl
```

### Run Integration Tests (Clean Environment Required)
⚠️ **Warning**: Integration tests require a clean Vault environment and will create real infrastructure.

```bash
# FIRST: Clean up existing infrastructure
task clean
task up

# THEN: Run integration tests
terraform test -filter=tests/ldap_auth_integration.tftest.hcl
terraform test -filter=tests/secrets_access_integration.tftest.hcl
terraform test -filter=tests/multi_backend_integration.tftest.hcl
```

### Run All Tests (Not Recommended)
```bash
# This will likely fail if infrastructure already exists
terraform test
```

### Run with Verbose Output
```bash
terraform test -verbose -filter=tests/vault_config_validation.tftest.hcl
```

## Test Categories

### 1. Configuration Validation Tests
- Verify Terraform provider configuration
- Validate audit logging setup
- Check KV secrets structure and content
- Test secret data integrity

### 2. LDAP Backend Tests
- Validate LDAP backend configuration
- Test token TTL settings
- Verify backend consistency
- Check LDAP connection parameters

### 3. Policy Tests
- Validate vault-admins policy capabilities
- Test app-secrets policy restrictions
- Verify policy file references
- Check policy assignment to groups

### 4. Identity Mapping Tests
- Test identity groups for LDAP backend
- Validate group aliases and their mappings
- Check entity and entity alias configurations
- Verify identity consistency

### 5. Integration Tests
- End-to-end infrastructure deployment
- Secret access pattern validation
- Policy enforcement testing
- Multi-backend authentication scenarios

## Key Test Scenarios

1. **Configuration Validation**: Verify all resources are properly configured with correct attributes
2. **LDAP Backend Testing**: Validate LDAP backend with proper settings
3. **Policy Enforcement**: Test vault-admins vs app-secrets policy access patterns
4. **Identity Mapping**: Verify user entities can authenticate via LDAP backend
5. **Secret Access Control**: Validate tiered access to `secret/app/*` vs `secret/restricted/*`
6. **Identity Consistency**: Test that user 'bob' maintains consistent identity

## Test Data

The tests use the following test data:
- **Test User**: `bob` (member of vault-admins group)
- **Test Password**: `password`
- **LDAP Server**: `ldap://ldap:389`
- **Secrets**: `secret/app/db` and `secret/restricted/db`
- **Policies**: `vault-admins` (full access) and `app-secrets` (limited access)

## Troubleshooting

### Common Issues

1. **Vault not running**: Ensure Vault is started with `task all`
2. **LDAP not available**: Check Docker containers are running
3. **Environment variables**: Verify `VAULT_ADDR` and `VAULT_TOKEN` are set
4. **Test failures**: Check Terraform state and Vault configuration

### Debug Commands

```bash
# Check Vault status
vault status

# List auth methods
vault auth list

# Check policies
vault policy list

# View identity groups
vault list identity/group/name
```

### Cleanup

Terraform tests automatically clean up resources after each test file execution. However, if tests fail unexpectedly, you may need to manually clean up:

```bash
# Reset Terraform state
terraform destroy -auto-approve

# Restart the stack
task clean
task all
```

## Development Notes

- Tests use both `command = plan` (unit tests) and `command = apply` (integration tests)
- Integration tests create real infrastructure and automatically clean up
- Each test file maintains isolated state in memory
- Tests are designed to be run independently or as a suite
- Helper modules provide common test utilities and configurations