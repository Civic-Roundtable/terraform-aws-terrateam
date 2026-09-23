variable "name" {
  description = "Name prefix for all resources."
  type        = string
  default     = "terrateam"
}

variable "vpc_id" {
  description = "ID of the VPC to deploy into."
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks and RDS."
  type        = list(string)
}

variable "domain" {
  description = "Public FQDN for the Terrateam instance (e.g. terrateam.example.com). Used to construct TERRAT_API_BASE, TERRAT_WEB_BASE_URL, and TERRAT_UI_BASE."
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of an ACM certificate for HTTPS. Only used when enable_https is true."
  type        = string
  default     = null
}

variable "enable_https" {
  description = "Create an HTTPS listener on port 443 (and redirect HTTP to it) using acm_certificate_arn. Kept as its own flag rather than inferred from acm_certificate_arn != null: when the certificate is created in the same apply as this module (e.g. from an ACM module whose output the caller passes in), its ARN is unknown at plan time, and Terraform can't use an unknown value to decide a resource's count - only a value that's statically known, like this flag, works there."
  type        = bool
  default     = false
}

variable "container_image" {
  description = "Docker image for the Terrateam container."
  type        = string
  default     = "ghcr.io/terrateamio/terrat-oss:latest"
}

variable "container_cpu" {
  description = "CPU units for the Fargate task (1 vCPU = 1024)."
  type        = number
  default     = 512
}

variable "container_memory" {
  description = "Memory (MiB) for the Fargate task."
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Number of ECS tasks to run."
  type        = number
  default     = 1
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_engine_version" {
  description = "PostgreSQL engine version for RDS."
  type        = string
  default     = "14.18"
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment for RDS."
  type        = bool
  default     = false
}

variable "db_deletion_protection" {
  description = "Enable deletion protection on the RDS instance."
  type        = bool
  default     = true
}

variable "db_backup_retention_period" {
  description = "Number of days to retain RDS automated backups."
  type        = number
  default     = 7
}

variable "alb_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to reach the ALB."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "extra_environment" {
  description = "Additional environment variables for the Terrateam container."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "assign_public_ip" {
  description = "Assign public IP to ECS tasks. Required when running in public subnets without a NAT gateway."
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Skip final snapshot when destroying RDS. Use for testing only."
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "KMS key ARN for encrypting the RDS instance's storage and Performance Insights data. Defaults to the AWS-managed key (alias/aws/rds) when not set - pass a customer-managed key's ARN to use one instead."
  type        = string
  default     = null
}

variable "log_retention_in_days" {
  description = "CloudWatch Logs retention (days) for the ECS task's log group."
  type        = number
  default     = 30
}

variable "db_parameters" {
  description = "Extra parameters for the RDS instance's parameter group. Defaults to none, matching the engine family's default parameter group."
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = []
}

variable "db_storage_type" {
  description = "RDS storage type."
  type        = string
  default     = "gp2"
}

variable "db_enabled_cloudwatch_logs_exports" {
  description = "RDS log types to export to CloudWatch Logs (e.g. [\"postgresql\", \"upgrade\"]). Defaults to none."
  type        = list(string)
  default     = []
}

variable "db_performance_insights_retention_period" {
  description = "Retention period (days) for RDS Performance Insights data. AWS default is 7; pass 465 (or higher, in 31-day increments) to use \"advanced\" database_insights_mode."
  type        = number
  default     = 7
}

variable "db_monitoring_interval" {
  description = "Granularity (seconds) for RDS Enhanced Monitoring metrics. 0 disables enhanced monitoring, which is the default - the IAM role enhanced monitoring needs is only created when this is nonzero."
  type        = number
  default     = 0
}

variable "db_database_insights_mode" {
  description = "RDS Performance Insights mode: \"standard\" (default) or \"advanced\". \"advanced\" requires db_performance_insights_retention_period >= 465."
  type        = string
  default     = "standard"
}

variable "db_log_retention_in_days" {
  description = "CloudWatch Logs retention (days) for the RDS-specific log groups this module precreates (postgresql/upgrade exports, and RDSOSMetrics when enhanced monitoring is on). Only applies to log groups actually created - i.e. exports listed in db_enabled_cloudwatch_logs_exports, and RDSOSMetrics only when db_monitoring_interval > 0."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
