# HashiCorp Vault Secrets Sync

## Overview
Secrets Sync allows you to automatically sync secrets from Vault Enterprise to a variety of third party platforms including AWS, Azure, GCP, GitHub, and Vercel.

## Diagram
<img src="https://www.hashicorp.com/_next/image?url=https%3A%2F%2Fwww.datocms-assets.com%2F2885%2F1712857918-vault-secrets-sync-final.png&w=3840&q=75">

## Demo

### Infrastructure Setup
```shell
cd vault-secrets-sync-demo/tf
terraform apply
export VAULT_ADDR=$(terraform output -raw vault_addr)
cd ..
```

### Vault Init
```shell
vault operator init -key-shares=1 -key-threshold=1 -format=json > init.json
vault operator unseal $(cat init.json | jq -r .unseal_keys_hex[0])
export VAULT_TOKEN=$(cat init.json| jq -r .root_token)
```

### Vault Setup
```shell
vault write -f sys/activation-flags/secrets-sync/activate
vault secrets enable -version=2 kv
```

### Add Secrets (Manual)
```shell
vault kv put kv/path/to/secret \
  username="foo" \
  password=$RANDOM \
  uuid=$(uuidgen)
```

### Add Secrets (Bulk)
Perform this step from your local machine.
```shell
./scripts/aws-to-vault.sh
```

### Setup Destination (Account + Region)
```shell
# default template
vault write sys/sync/destinations/aws-sm/demo-use2 \
  role_arn="arn:aws:iam::$AWS_ACCOUNT_ID:role/demo-secrets-sync" \
  region="us-east-2"

# custom template (be cautious of overwrites)
# https://developer.hashicorp.com/vault/docs/sync#name-template
vault write sys/sync/destinations/aws-sm/demo-use2-templated \
  role_arn="arn:aws:iam::$AWS_ACCOUNT_ID:role/demo-secrets-sync" \
  region="us-east-2" \
  secret_name_template="vault/{{ if .NamespacePath }}{{ .NamespacePath }}/{{ else }}{{ end }}{{ .MountPath }}/{{ .SecretPath }}"
```

### Sync Secrets (Manual)
```shell
vault write sys/sync/destinations/aws-sm/demo-use2/associations/set \
  mount="kv" \
  secret_name="path/to/secret"
```

### Sync Secrets (Bulk)
Perform this step from your local machine.
```shell
./scripts/vault-to-aws.sh
```

### AWS Console
View the replicated secrets in [AWS Secrets Manager](https://console.aws.amazon.com/secretsmanager/listsecrets)

### Modify Secrets in Vault
Perform the modifications below in Vault; then view the changes replicated in [AWS Secrets Manager](https://console.aws.amazon.com/secretsmanager/listsecrets)
```shell
vault kv patch kv/path/to/secret foo="bar" hello="world"
```

### Vault UI
View the secrets and secrets sync settings within the Vault UI.

### Cleanup
```shell
./scripts/cleanup.sh
cd tf/
terraform destroy
```
