output "demo_vault_id" {
  value = aws_instance.this.id
}

output "demo_vault_public_ip" {
  value = aws_instance.this.public_ip
}
