data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# --- Task Execution Role (pulls images, reads secrets, writes logs) ---

resource "aws_iam_role" "task_execution" {
  name_prefix        = "${var.name}-exec-"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "secrets_read" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      aws_secretsmanager_secret.db_password.arn,
      aws_secretsmanager_secret.github_app_id.arn,
      aws_secretsmanager_secret.github_app_client_id.arn,
      aws_secretsmanager_secret.github_app_client_secret.arn,
      aws_secretsmanager_secret.github_app_pem.arn,
      aws_secretsmanager_secret.github_webhook_secret.arn,
    ]
  }
}

resource "aws_iam_role_policy" "secrets_read" {
  name_prefix = "${var.name}-secrets-"
  role        = aws_iam_role.task_execution.id
  policy      = data.aws_iam_policy_document.secrets_read.json
}

# --- Task Role (empty; users attach policies for workload identity, OIDC, etc.) ---

resource "aws_iam_role" "task" {
  name_prefix        = "${var.name}-task-"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
  tags               = var.tags
}
