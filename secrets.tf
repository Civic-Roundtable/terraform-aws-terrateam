resource "random_password" "db" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "db_password" {
  name_prefix = "${var.name}/db-password-"
  description = "Terrateam RDS password (auto-generated)"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db.result
}

resource "aws_secretsmanager_secret" "github_app_id" {
  name_prefix = "${var.name}/github-app-id-"
  description = "GitHub App ID — populate after apply"
  tags        = var.tags
}

resource "aws_secretsmanager_secret" "github_app_client_id" {
  name_prefix = "${var.name}/github-app-client-id-"
  description = "GitHub App Client ID — populate after apply"
  tags        = var.tags
}

resource "aws_secretsmanager_secret" "github_app_client_secret" {
  name_prefix = "${var.name}/github-app-client-secret-"
  description = "GitHub App Client Secret — populate after apply"
  tags        = var.tags
}

resource "aws_secretsmanager_secret" "github_app_pem" {
  name_prefix = "${var.name}/github-app-pem-"
  description = "GitHub App private key (PEM) — populate after apply"
  tags        = var.tags
}

resource "aws_secretsmanager_secret" "github_webhook_secret" {
  name_prefix = "${var.name}/github-webhook-secret-"
  description = "GitHub webhook secret — populate after apply"
  tags        = var.tags
}
