variable "name" {
  type    = string
  default = "secrets-sync"
}

variable "vault_license" {
  type      = string
  sensitive = true
}
