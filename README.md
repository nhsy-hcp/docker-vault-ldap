# docker-vault-ldap

## Description
This repository contains a docker compose stack with the following services:
- openldap
- phpLDAPadmin
- Vault

## Pre-requisites
Install `taskfile` and `jq` with the following command:
```shell
brew install go-task jq
```
Install `terraform`with the following command:
```shell
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

Clone git repository:
```shell
git clone https://github.com/nhsy-hcp/docker-vault-ldap.git
```

## Usage
[Taskfile.yml](Taskfile.yml) contains automation commands to manage the stack.

Launch the docker compose stack with the following command:
```bash
task up
task post-install
```

Export the environment variables with the following command:
```shell
export VAULT_ADDR=http://localhost:8200
export VAULT_TOKEN=root
vault token lookup
```

Navigate to the following urls:
- https://localhost:6443 - PHPLDAPadmin
- http://localhost:8200/ - Vault
