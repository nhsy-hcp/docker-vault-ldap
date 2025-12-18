# Vault LDAP Integration Demo

## Description
This repository demonstrates HashiCorp Vault LDAP authentication integration using Docker Compose. The stack includes:
- **HashiCorp Vault** - Secrets management server (development mode)
- **OpenLDAP** - LDAP directory server with sample users and groups
- **phpLDAPadmin** - Web-based LDAP administration interface
- **Terraform** - Infrastructure as code for Vault configuration

## Features
- Dual LDAP authentication backends (`ldap1`, `ldap2`)
- Identity entity mapping across multiple LDAP directories
- Group-based policy assignment (vault-admins, developers)
- KV secrets engine with tiered access control
- Sample users: `bob` (vault-admins group), `alice` (developers group)
- LDAP secret engine configured with static role for `alice` (does not auto-rotate)
- LDAP secret engine configured with dynamic role for a person in `developers` group

## Pre-requisites
Install `taskfile` and `jq` with the following command:
```shell
brew install go-task jq
```
Install `terraform` with the following command:
```shell
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

Clone git repository:
```shell
git clone https://github.com/nhsy-hcp/docker-vault-ldap.git
```

## Quick Start

1. **Launch the complete stack:**
   ```bash
   task all
   ```
   This command will:
   - Start Docker containers (Vault, LDAP, phpLDAPadmin)
   - Initialize Terraform and apply Vault configuration
   - Configure LDAP authentication backends
   - Create sample users and policies

2. **Set environment variables:**
   ```shell
   export VAULT_ADDR=http://localhost:8200
   export VAULT_TOKEN=root
   # Or use the helper script
   ./scripts/10_vault_vars.sh
   ```

3. **Access the services:**
   - **Vault UI:** http://localhost:8200/ (Token: `root`)
   - **phpLDAPadmin:** https://localhost:6443 (DN: `cn=admin,dc=example,dc=com`, Password: `admin`)

## Common Tasks

```bash
# View service status
task status

# View logs
task logs
task logs-vault

# Stop services
task stop

# Clean up and rebuild
task clean all
```

## Testing LDAP Authentication

### Test vault-admins group access (Bob)
```shell
# Login as Bob (member of vault-admins group)
LDAP_BOB=$(vault login -method=ldap -path=ldap1 -field=token username=bob password=password)

# Bob can access restricted secrets
VAULT_TOKEN=$LDAP_BOB vault kv get secret/restricted/db

# Bob can also access app secrets
VAULT_TOKEN=$LDAP_BOB vault kv get secret/app/db
```

### Test developers group access (Alice)
```shell
# Login as Alice (member of developers group)
LDAP_ALICE=$(vault login -method=ldap -path=ldap1 -field=token username=alice password=password)

# Alice can access app secrets
VAULT_TOKEN=$LDAP_ALICE vault kv get secret/app/db

# Alice cannot access restricted secrets (should fail)
VAULT_TOKEN=$LDAP_ALICE vault kv get secret/restricted/db
```

### Test multiple LDAP backends
```shell
# Test ldap1 backend
vault login -method=ldap -path=ldap2 username=bob password=password

# Test ldap2 backend
vault login -method=ldap -path=ldap2 username=bob password=password
```

### Test LDAP secret engine dynamic role
```shell
vault read ldap/creds/developer 
```

## Architecture Overview

The stack demonstrates:
- **Multiple LDAP Authentication Backends:** Two separate LDAP auth methods (`ldap1`, `ldap2`) pointing to the same LDAP server
- **Identity Entities:** User `bob` can authenticate via either LDAP backend but maintains consistent identity
- **Group Mapping:** LDAP groups are mapped to Vault policies through external identity groups
- **Policy-Based Access:** 
  - `vault-admins` policy: Full access to secrets and Vault administration
  - `app-secrets` policy: Limited access to application secrets only

> **Note:** External groups can have one (and only one) alias. For more details, see the [Vault Identity documentation](https://developer.hashicorp.com/vault/docs/concepts/identity).

## Terraform Testing

This project includes comprehensive Terraform tests using the native testing framework (Terraform 1.6+). Tests validate the entire Vault LDAP integration configuration.

### Test Structure

- **Unit Tests** (Plan-based validation) - Fast configuration validation without creating resources
- **Integration Tests** (Apply-based validation) - End-to-end testing with real infrastructure
- **Helper Modules** - Common test utilities and configurations

### Running Tests

```bash
# Run all tests
terraform test

# Run specific test file
terraform test -filter=tests/vault_config_validation.tftest.hcl

# Run with verbose output
terraform test -verbose

# Run unit tests (fast, recommended)
terraform test -filter=tests/vault_config_validation.tftest.hcl -filter=tests/ldap_backends_validation.tftest.hcl -filter=tests/policies_validation.tftest.hcl -filter=tests/identity_mapping_validation.tftest.hcl

# Run integration tests (requires clean environment)
task clean up
terraform test -filter=tests/ldap_auth_integration.tftest.hcl
terraform test -filter=tests/secrets_access_integration.tftest.hcl
terraform test -filter=tests/multi_backend_integration.tftest.hcl
```

### Test Coverage

- **Configuration validation:** Provider setup, audit logging, secrets structure
- **LDAP backend testing:** Dual backend configuration, token TTL, consistency
- **Policy enforcement:** vault-admins vs app-secrets access patterns
- **Identity mapping:** Cross-backend user identity, group mappings
- **Secret access control:** Tiered access to `secret/app/*` vs `secret/restricted/*`
- **Multi-backend scenarios:** User consistency across ldap1/ldap2

### Prerequisites for Testing

1. **Terraform 1.6.0+** - Required for native testing framework
2. **Running services:** Use `task all` to start Vault and LDAP
3. **Clean environment:** For integration tests, ensure no existing Vault resources conflict
4. **Environment variables:**
   ```bash
   export VAULT_ADDR=http://localhost:8200
   export VAULT_TOKEN=root
   ```

### Known Test Issues

**Resource conflicts:** Integration tests may fail if previous test resources exist in Vault. Common errors include:
- "path already in use at ldap1/" - LDAP auth backends already mounted
- "group already exists" - Identity groups from previous runs
- "audit backend: path already in use" - Audit logging already configured

**Solutions:**
- Restart Vault container: `task clean up` or `docker-compose restart vault`
- Use terraform destroy: `terraform destroy -auto-approve` (if applicable)
- Run unit tests only for configuration validation without resource creation

See `tests/README.md` for detailed testing documentation.

## Troubleshooting

- **Services not starting:** Check Docker is running and ports 8200, 6443 are available
- **Vault sealed:** Run `task status` to check Vault status; development mode auto-unseals
- **LDAP authentication fails:** Verify LDAP container is running and user data is loaded
- **Terraform errors:** Ensure Vault is running and accessible before applying Terraform configuration
- **Test failures:** Check test prerequisites and verify services are running with `task status`

## Additional Resources
- [Vault LDAP authentication documentation](https://developer.hashicorp.com/vault/docs/auth/ldap)
- [Vault Identity documentation](https://developer.hashicorp.com/vault/docs/concepts/identity)