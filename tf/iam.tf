# Create IAM Role
resource "aws_iam_role" "vault" {
  name = "demo-vault"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  # inline policy for demo purposes
  inline_policy {
    name = "demo-assume-vault-secrets-sync"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["sts:AssumeRole"]
          Effect   = "Allow"
          Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/demo-vault-secrets-sync"
        },
      ]
    })
  }
}

# Create Instance Profile
resource "aws_iam_instance_profile" "vault" {
  name = aws_iam_role.vault.name
  role = aws_iam_role.vault.name
}

# Attach Policy to IAM Role (SSM)
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.vault.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

#
# Secrets Sync
#

# Create IAM Role for Secrets Sync
resource "aws_iam_role" "secrets_sync" {
  name = "demo-vault-secrets-sync"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          AWS = aws_iam_role.vault.arn
        }
      }
    ]
  })
}

# Define Secrets Sync Policy
data "aws_iam_policy_document" "secrets_sync" {
  statement {
    effect    = "Allow"
    resources = ["arn:aws:secretsmanager:*:${data.aws_caller_identity.current.account_id}:secret:vault/*"]
    actions   = ["secretsmanager:*"]

    condition {
      test     = "StringEquals"
      variable = "secretsmanager:ResourceTag/hashicorp:vault"
      values   = [""]
    }
  }
}

# Create Secrets Sync Policy
resource "aws_iam_policy" "secrets_sync" {
  name        = aws_iam_role.secrets_sync.name
  description = "Demo policy for Vault Secrets Sync"
  policy      = data.aws_iam_policy_document.secrets_sync.json
}

# Attach secrets sync policy to role
resource "aws_iam_role_policy_attachment" "secrets_sync" {
  role       = aws_iam_role.secrets_sync.name
  policy_arn = aws_iam_policy.secrets_sync.arn
}
