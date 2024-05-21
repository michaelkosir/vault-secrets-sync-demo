variable "team" {
  type = string
}

resource "random_uuid" "this" {}

resource "random_pet" "this" {}

resource "random_password" "this" {
  length = 16
}

resource "random_bytes" "this" {
  length = 64
}

resource "aws_secretsmanager_secret" "this" {
  name                    = "demo/${var.team}/webapp-${random_pet.this.id}"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({
    uuid     = random_uuid.this.result,
    bytes    = random_bytes.this.base64,
    password = random_password.this.result,
  })
}
