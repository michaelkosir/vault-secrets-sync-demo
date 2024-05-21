# HashiCorp Vault Secrets Sync

## Overview
Secrets Sync allows you to automatically sync secrets from Vault Enterprise to a variety of third party platforms including AWS, Azure, GCP, GitHub, and Vercel.

## Diagram
<img src="https://www.hashicorp.com/_next/image?url=https%3A%2F%2Fwww.datocms-assets.com%2F2885%2F1712857918-vault-secrets-sync-final.png&w=3840&q=75">

## Demo

### Infrastructure Setup
```shell
git clone ...
cd ./vault-secrets-sync-demo/
terraform -chdir=tf apply
```

### Vault Setup
Using AWS Session Manager, connect to the EC2 Instance
```shell
# add license and start vault
sudo nano /etc/vault.d/vault.hclic
sudo systemctl start vault

# init vault
export VAULT_ADDR="http://localhost:8200"
vault operator init -format=json -key-shares=1 -key-threshold=1 | sudo tee /home/ssm-user/init.json
source /home/ssm-user/vault.env
vault operator unseal $VAULT_UNSEAL

# activation and mount setup
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
Perform this step from your local machine. This may require opening port `8200` on the AWS security group.
```shell
# set AWS and Vault EnvVars
export ...
./scripts/aws-to-vault.sh
```

### Setup Destination (Account + Region)
```shell
# default template
vault write sys/sync/destinations/aws-sm/demo-use2 \
  role_arn="arn:aws:iam::$AWS_ACCOUNT_ID:role/demo-vault-secrets-sync" \
  region="us-east-2"

# custom template (be cautious of overwrites)
# https://developer.hashicorp.com/vault/docs/sync#name-template
vault write sys/sync/destinations/aws-sm/demo-use2-templated \
  role_arn="arn:aws:iam::$AWS_ACCOUNT_ID:role/demo-vault-secrets-sync" \
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
Perform this step from your local machine. This may require opening port `8200` on the AWS security group.
```shell
# set Vault EnvVars
export ...
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
terraform -chdir=tf destroy
./scripts/cleanup.sh
```
