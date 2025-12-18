# Vault LDAP Integration Lab

[![CI](https://github.com/nhsy-hcp/docker-vault-ldap/actions/workflows/ci.yml/badge.svg)](https://github.com/nhsy-hcp/docker-vault-ldap/actions/workflows/ci.yml)

## Description
This repository demonstrates HashiCorp Vault LDAP authentication integration using Docker Compose. The stack includes:
- **HashiCorp Vault** - Secrets management server (development mode)
- **OpenLDAP** - LDAP directory server with sample users and groups
- **phpLDAPadmin** - Web-based LDAP administration interface
- **Terraform** - Infrastructure as code for Vault configuration

## Features
- LDAP authentication backend integration
- Identity entity mapping with group-based policy assignment
- Group-based policy assignment (vault-admins, developers)
- KV secrets engine with tiered access control
- Sample users: `bob` (vault-admins group), `alice` (developers group)
- LDAP secret engine configured with static role for `alice` with automatic rotation
- LDAP secret engine configured with dynamic role for temporary `developers` group members

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
LDAP_BOB=$(vault login -method=ldap -path=ldap -field=token username=bob password=password)

# Bob can access restricted secrets
VAULT_TOKEN=$LDAP_BOB vault kv get secret/restricted/db

# Bob can also access app secrets
VAULT_TOKEN=$LDAP_BOB vault kv get secret/app/db
```

### Test developers group access (Alice)
```shell
# Login as Alice (member of developers group)
LDAP_ALICE=$(vault login -method=ldap -path=ldap -field=token username=alice password=password)

# Alice can access app secrets
VAULT_TOKEN=$LDAP_ALICE vault kv get secret/app/db

# Alice cannot access restricted secrets (should fail)
VAULT_TOKEN=$LDAP_ALICE vault kv get secret/restricted/db
```


### Test LDAP secret engine alice static role
```bash
vault read ldap/static-cred/alice

Key                    Value                                                                                                                                                                                                   
---                    -----
dn                     cn=alice,ou=users,dc=example,dc=com
last_password          xthtklFBPJhuP7MwWwJyCyPZ6ksipxfc0jrWwwJGoJpSJfepcsowx8A6ncIbPk3N
last_vault_rotation    2025-12-18T16:32:59.681210661Z
password               GNE1O5IGvlVCkLdoYmZGFTw99KsESAEXlIbOZXHqQ0Ocse9uiSbwIy3vs6FH6mzp
rotation_period        5m
ttl                    5m
username               alice
```

### Test LDAP secret engine dynamic role
```shell
vault read ldap/creds/developer 

Key                    Value                                                                                                                                                                                                   
---                    -----
lease_id               ldap/creds/developer/FAAG36B9Zkn5EBHibkr8jU8B
lease_duration         5m
lease_renewable        true
distinguished_names    [cn=developer_adEddN1ev4,ou=users,dc=example,dc=com cn=developers,ou=groups,dc=example,dc=com]
password               IdsHXMyZQnNC5dqfU7B71DZJYFfcm8hDpDnhaNXY8GDqmPCgCv2xh5MndFAHFCix
username               developer_adEddN1ev4
```

## Architecture Overview

The stack demonstrates:
- **LDAP Authentication Backend:** Single LDAP auth method at `/auth/ldap` connecting to OpenLDAP server
- **Identity Entities:** Users authenticate via LDAP and are mapped to Vault identity entities
- **Group Mapping:** LDAP groups are mapped to Vault policies through external identity groups
- **Policy-Based Access:**
  - `vault-admins` policy: Full access to secrets and Vault administration
  - `app-secrets` policy: Limited access to application secrets only
- **LDAP Secrets Engine:** Manages both static credentials (with rotation) and dynamic credentials

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
```

### Test Coverage

- **Configuration validation:** Provider setup, audit logging, secrets structure
- **LDAP backend testing:** Backend configuration, token TTL, connection settings
- **Policy enforcement:** vault-admins vs app-secrets access patterns
- **Identity mapping:** User identity entities and group mappings
- **Secret access control:** Tiered access to `secret/app/*` vs `secret/restricted/*`
- **LDAP secrets engine:** Static role rotation and dynamic credential generation

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
- "path already in use at ldap/" - LDAP auth backend already mounted
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