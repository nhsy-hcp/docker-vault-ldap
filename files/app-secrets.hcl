path "secret/data/app/*" {
  capabilities = ["read", "list", "create", "update", "delete"]
}

path "secret/metadata" {
  capabilities = ["list"]
}

path "secret/metadata/app/*" {
  capabilities = ["read", "list", "create", "update", "delete"]
}