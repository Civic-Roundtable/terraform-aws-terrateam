output "alb_dns_name" {
  description = "ALB DNS name — create a DNS CNAME record pointing your domain here."
  value       = module.terrateam.alb_dns_name
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = module.terrateam.ecs_cluster_name
}

output "ecs_service_name" {
  description = "ECS service name."
  value       = module.terrateam.ecs_service_name
}

output "secret_arns" {
  description = "Secrets Manager ARNs — populate the GitHub App secrets after apply."
  value       = module.terrateam.secret_arns
}

output "terrateam_url" {
  description = "URL for the Terrateam instance."
  value       = module.terrateam.terrateam_url
}
