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

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
