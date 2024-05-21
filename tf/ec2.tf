# Search for latest AL2023 AMI
data "aws_ami" "al2023" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

# Create EC2
resource "aws_instance" "this" {
  instance_type               = "t3.small"
  associate_public_ip_address = true
  vpc_security_group_ids      = ["sg-00e0cfca53a6915e2"]

  ami                  = data.aws_ami.al2023.id
  iam_instance_profile = aws_iam_instance_profile.vault.name
  user_data            = file("./config/cloud-config.yml")

  tags = {
    Name = "demo-vault-secrets-sync"
  }
}
