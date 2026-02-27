data "aws_region" "current" {}

resource "aws_ecs_cluster" "this" {
  name = var.name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

locals {
  protocol = var.acm_certificate_arn != null ? "https" : "http"
  base_url = "${local.protocol}://${var.domain}"

  base_environment = [
    { name = "DB_HOST", value = aws_db_instance.this.address },
    { name = "DB_PORT", value = "5432" },
    { name = "DB_USER", value = "terrateam" },
    { name = "DB_NAME", value = "terrateam" },
    { name = "TERRAT_API_BASE", value = "${local.base_url}/api" },
    { name = "TERRAT_WEB_BASE_URL", value = local.base_url },
    { name = "TERRAT_UI_BASE", value = local.base_url },
    { name = "TERRAT_TELEMETRY_LEVEL", value = "disabled" },
  ]

  environment = concat(local.base_environment, var.extra_environment)

  secrets = [
    { name = "DB_PASS", valueFrom = aws_secretsmanager_secret.db_password.arn },
    { name = "GITHUB_APP_ID", valueFrom = aws_secretsmanager_secret.github_app_id.arn },
    { name = "GITHUB_APP_CLIENT_ID", valueFrom = aws_secretsmanager_secret.github_app_client_id.arn },
    { name = "GITHUB_APP_CLIENT_SECRET", valueFrom = aws_secretsmanager_secret.github_app_client_secret.arn },
    { name = "GITHUB_APP_PEM", valueFrom = aws_secretsmanager_secret.github_app_pem.arn },
    { name = "GITHUB_WEBHOOK_SECRET", valueFrom = aws_secretsmanager_secret.github_webhook_secret.arn },
  ]
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = var.name
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        },
      ]

      environment = local.environment
      secrets     = local.secrets

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.this.name
          "awslogs-region"        = data.aws_region.current.id
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },
  ])

  tags = var.tags
}

resource "aws_ecs_service" "this" {
  name            = var.name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  health_check_grace_period_seconds = 300

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.name
    container_port   = 8080
  }

  tags = var.tags
}
