# Create demo secrets in Secrets Manager
# so we can import them into Vault
module "eng" {
  source = "./modules/secret"
  count  = 10
  team   = "engineering"
}

module "sec" {
  source = "./modules/secret"
  count  = 10
  team   = "security"
}
