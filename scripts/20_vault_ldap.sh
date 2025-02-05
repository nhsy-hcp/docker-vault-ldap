#!/bin/bash
set -xe

export VAULT_ADDR=http://localhost:8200
export VAULT_TOKEN=root

vault audit enable file file_path=stdout || true

vault auth enable -path=ldap1 ldap || true
vault write auth/ldap1/config \
    url="ldap://ldap:389" \
    userdn="ou=users,dc=example,dc=com" \
    userattr="cn" \
    groupdn="ou=groups,dc=example,dc=com" \
    groupfilter="(|(memberUid={{.Username}})(member={{.UserDN}}))" \
    groupattr="cn" \
    binddn="cn=admin,dc=example,dc=com" \
    bindpass="admin" \
    token_ttl=1h \
    token_max_ttl=24h

vault policy write vault-admins ./files/vault-admins.hcl

#vault write auth/ldap/groups/vault-admins policies=vault-admins

vault auth enable -path=ldap2 ldap || true

vault write auth/ldap2/config \
    url="ldap://ldap2:389" \
    userdn="ou=users,dc=example2,dc=com" \
    userattr="cn" \
    groupdn="ou=groups,dc=example2,dc=com" \
    groupfilter="(|(memberUid={{.Username}})(member={{.UserDN}}))" \
    groupattr="cn" \
    binddn="cn=admin,dc=example2,dc=com" \
    bindpass="admin" \
    token_ttl=1h \
    token_max_ttl=24h

#vault write auth/ldap2/groups/vault-admins policies=vault-admins

LDAP1_ACCESSOR=$(vault auth list -format=json | jq -r '.["ldap1/"] | .accessor')
LDAP2_ACCESSOR=$(vault auth list -format=json | jq -r '.["ldap2/"] | .accessor')

vault write identity/group name="ldap1-vault-admins" policies="vault-admins" type=external || true
vault write identity/group name="ldap2-vault-admins" policies="vault-admins" type=external || true

LDAP1_ADMIN_GROUP_ID=$(vault read identity/group/name/ldap1-vault-admins type=external -format=json | jq -r '.data.id')
LDAP2_ADMIN_GROUP_ID=$(vault read identity/group/name/ldap2-vault-admins type=external -format=json | jq -r '.data.id')
vault write identity/group-alias name="vault-admins" mount_accessor=$LDAP1_ACCESSOR canonical_id=$LDAP1_ADMIN_GROUP_ID|| true
vault write identity/group-alias name="vault-admins" mount_accessor=$LDAP2_ACCESSOR canonical_id=$LDAP2_ADMIN_GROUP_ID || true

vault write identity/entity name="ldap-bob" metadata="organization=example inc" metadata="dept=platform team" || true

USER_CANONICAL_ID=$(vault read identity/entity/name/ldap-bob -format=json | jq -r '.data.id')

vault write identity/entity-alias name="bob" canonical_id=$USER_CANONICAL_ID mount_accessor=$LDAP1_ACCESSOR || true
vault write identity/entity-alias name="bob" canonical_id=$USER_CANONICAL_ID mount_accessor=$LDAP2_ACCESSOR || true

vault policy write app-secrets ./files/app-secrets.hcl
vault write identity/group name="ldap1-developers" policies="app-secrets" type=external || true

LDAP1_DEV_GROUP_ID=$(vault read identity/group/name/ldap1-developers type=external -format=json | jq -r '.data.id')
vault write identity/group-alias name="developers" mount_accessor=$LDAP1_ACCESSOR canonical_id=$LDAP1_DEV_GROUP_ID|| true

vault kv put secret/app/db username=app password=w1bble
vault kv put secret/restricted/db username=app password=w1bble