# terraform-aws-terrateam

Terraform module to deploy [Terrateam](https://terrateam.io) on AWS using ECS/Fargate, ALB, and RDS PostgreSQL.

## Prerequisites

- An existing VPC with public and private subnets (or public-only with `assign_public_ip = true`)
- Private subnets must have NAT gateway access unless using `assign_public_ip = true`
- A GitHub App configured for Terrateam ([setup guide](https://docs.terrateam.io/quickstart/self-hosted/))
- (Optional) An ACM certificate for HTTPS

## Usage

```hcl
module "terrateam" {
  source  = "terrateamio/terrateam/aws"

  vpc_id             = "vpc-0123456789abcdef0"
  public_subnet_ids  = ["subnet-aaa", "subnet-bbb"]
  private_subnet_ids = ["subnet-ccc", "subnet-ddd"]
  domain             = "terrateam.example.com"

  # Optional: enable HTTPS
  # acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxxxxx"

  tags = {
    Environment = "production"
  }
}
```

## Post-Apply Steps

After `terraform apply` completes:

### 1. Create a DNS record

Point your domain to the ALB:

```
terrateam.example.com → <alb_dns_name output>
```

If using Route 53, create an alias record using the `alb_dns_name` and `alb_zone_id` outputs.

### 2. Populate GitHub App secrets

The module creates empty Secrets Manager secrets for your GitHub App credentials. Populate them using the ARNs from the `secret_arns` output:

```bash
aws secretsmanager put-secret-value \
  --secret-id <github_app_id ARN> \
  --secret-string '<YOUR_APP_ID>'

aws secretsmanager put-secret-value \
  --secret-id <github_app_client_id ARN> \
  --secret-string '<YOUR_CLIENT_ID>'

aws secretsmanager put-secret-value \
  --secret-id <github_app_client_secret ARN> \
  --secret-string '<YOUR_CLIENT_SECRET>'

aws secretsmanager put-secret-value \
  --secret-id <github_webhook_secret ARN> \
  --secret-string '<YOUR_WEBHOOK_SECRET>'
```

For the PEM private key, if you have a `.pem` file:

```bash
aws secretsmanager put-secret-value \
  --secret-id <github_app_pem ARN> \
  --secret-string file://private-key.pem
```

If using the `.env` file from the Setup Wizard (which contains `\n` escape sequences):

```bash
PEM_RAW=$(grep '^GITHUB_APP_PEM=' .env | sed 's/^GITHUB_APP_PEM=//')
printf '%b' "$PEM_RAW" | aws secretsmanager put-secret-value \
  --secret-id <github_app_pem ARN> \
  --secret-string file:///dev/stdin
```

### 3. Redeploy ECS

Force ECS to pick up the new secrets:

```bash
aws ecs update-service \
  --cluster <ecs_cluster_name output> \
  --service <ecs_service_name output> \
  --force-new-deployment
```

### 4. Verify

```bash
curl https://terrateam.example.com/health
```

A `200` response means both the application and database are healthy.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `vpc_id` | VPC ID | `string` | — | yes |
| `public_subnet_ids` | Public subnet IDs for ALB | `list(string)` | — | yes |
| `private_subnet_ids` | Private subnet IDs for ECS + RDS | `list(string)` | — | yes |
| `domain` | Public FQDN for the instance | `string` | — | yes |
| `name` | Name prefix for all resources | `string` | `"terrateam"` | no |
| `acm_certificate_arn` | ACM certificate ARN for HTTPS | `string` | `null` | no |
| `container_image` | Docker image | `string` | `"ghcr.io/terrateamio/terrat-oss:latest"` | no |
| `container_cpu` | Fargate CPU units | `number` | `512` | no |
| `container_memory` | Fargate memory (MiB) | `number` | `1024` | no |
| `desired_count` | ECS task count | `number` | `1` | no |
| `db_instance_class` | RDS instance class | `string` | `"db.t4g.micro"` | no |
| `db_engine_version` | PostgreSQL version | `string` | `"14.18"` | no |
| `db_multi_az` | Enable RDS Multi-AZ | `bool` | `false` | no |
| `db_deletion_protection` | Enable RDS deletion protection | `bool` | `true` | no |
| `db_backup_retention_period` | RDS backup retention (days) | `number` | `7` | no |
| `alb_ingress_cidr_blocks` | CIDRs allowed to reach the ALB | `list(string)` | `["0.0.0.0/0"]` | no |
| `assign_public_ip` | Assign public IP to ECS tasks (required in public subnets without NAT) | `bool` | `false` | no |
| `extra_environment` | Additional container env vars | `list(object)` | `[]` | no |
| `db_skip_final_snapshot` | Skip final snapshot on RDS destroy (testing only) | `bool` | `false` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `alb_dns_name` | ALB DNS name |
| `alb_zone_id` | ALB Route 53 zone ID |
| `ecs_cluster_name` | ECS cluster name |
| `ecs_service_name` | ECS service name |
| `task_role_arn` | ECS task role ARN (attach additional policies here) |
| `db_endpoint` | RDS endpoint |
| `secret_arns` | Map of all Secrets Manager ARNs |
| `terrateam_url` | Constructed URL for the instance |
| `alb_security_group_id` | ALB security group ID |
| `ecs_security_group_id` | ECS security group ID |
| `rds_security_group_id` | RDS security group ID |
