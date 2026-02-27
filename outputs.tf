output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer."
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Route 53 zone ID of the ALB (for alias records)."
  value       = aws_lb.this.zone_id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster."
  value       = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  description = "Name of the ECS service."
  value       = aws_ecs_service.this.name
}

output "task_role_arn" {
  description = "ARN of the ECS task role. Attach additional policies here (e.g. for OIDC provider access)."
  value       = aws_iam_role.task.arn
}

output "db_endpoint" {
  description = "RDS instance endpoint (host:port)."
  value       = aws_db_instance.this.endpoint
}

output "secret_arns" {
  description = "Map of Secrets Manager secret ARNs."
  value = {
    db_password            = aws_secretsmanager_secret.db_password.arn
    github_app_id          = aws_secretsmanager_secret.github_app_id.arn
    github_app_client_id   = aws_secretsmanager_secret.github_app_client_id.arn
    github_app_client_secret = aws_secretsmanager_secret.github_app_client_secret.arn
    github_app_pem         = aws_secretsmanager_secret.github_app_pem.arn
    github_webhook_secret  = aws_secretsmanager_secret.github_webhook_secret.arn
  }
}

output "terrateam_url" {
  description = "URL for the Terrateam instance."
  value       = var.acm_certificate_arn != null ? "https://${var.domain}" : "http://${var.domain}"
}

output "alb_security_group_id" {
  description = "Security group ID of the ALB."
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "Security group ID of the ECS tasks."
  value       = aws_security_group.ecs.id
}

output "rds_security_group_id" {
  description = "Security group ID of the RDS instance."
  value       = aws_security_group.rds.id
}
