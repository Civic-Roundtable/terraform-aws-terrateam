resource "aws_db_subnet_group" "this" {
  name_prefix = "${var.name}-"
  subnet_ids  = var.private_subnet_ids
  tags        = var.tags
}

# family must track the major version of var.db_engine_version (e.g. "postgres14" for "14.18").
resource "aws_db_parameter_group" "this" {
  name_prefix = "${var.name}-"
  family      = "postgres${split(".", var.db_engine_version)[0]}"

  parameter {
    name  = "autovacuum"
    value = "1"
  }
  parameter {
    name  = "client_encoding"
    value = "utf8"
  }
  parameter {
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements,pg_tle,pgaudit"
    apply_method = "pending-reboot"
  }
  parameter {
    name         = "pgaudit.log"
    value        = "write,ddl"
    apply_method = "pending-reboot"
  }

  tags = var.tags
}

data "aws_iam_policy_document" "rds_enhanced_monitoring_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  name_prefix        = "${var.name}-rds-monitoring-"
  assume_role_policy = data.aws_iam_policy_document.rds_enhanced_monitoring_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_db_instance" "this" {
  identifier_prefix = "${var.name}-"

  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  db_name  = "terrateam"
  username = "terrateam"
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.this.name

  storage_encrypted     = true
  storage_type          = "gp3"
  allocated_storage     = 20
  max_allocated_storage = 100
  kms_key_id            = var.kms_key_id

  enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]
  performance_insights_enabled          = true
  performance_insights_retention_period = 465 # minimum required to enable "advanced" insights
  performance_insights_kms_key_id       = var.kms_key_id
  monitoring_interval                   = 60
  monitoring_role_arn                   = aws_iam_role.rds_enhanced_monitoring.arn
  database_insights_mode                = "advanced"

  multi_az                = var.db_multi_az
  backup_retention_period = var.db_backup_retention_period
  deletion_protection     = var.db_deletion_protection

  skip_final_snapshot       = var.db_skip_final_snapshot
  final_snapshot_identifier = var.db_skip_final_snapshot ? null : "${var.name}-final"

  tags = var.tags

  depends_on = [aws_iam_role_policy_attachment.rds_enhanced_monitoring]
}

# AWS auto-creates these when enabled_cloudwatch_logs_exports activates, but with no expiry -
# creating them ourselves first gets our own retention setting applied instead.
resource "aws_cloudwatch_log_group" "rds_postgresql" {
  name              = "/aws/rds/instance/${aws_db_instance.this.identifier}/postgresql"
  retention_in_days = 365
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "rds_upgrade" {
  name              = "/aws/rds/instance/${aws_db_instance.this.identifier}/upgrade"
  retention_in_days = 365
  tags              = var.tags
}

# Vanta requires retaining logs for at least 1 year. "RDSOSMetrics" is one log group shared by
# every RDS instance with enhanced monitoring enabled in this account+region, not specific to
# this instance - so if some other, unrelated RDS instance in the same account/region already
# has enhanced monitoring on, this resource will fail to create with "already exists". Terraform
# import blocks are only valid in the root module, and this is a child module always consumed by
# something else, so this can't self-heal that case the way a root module's own rds.tf could
# (see e.g. tf-root-modules/production-gov/backend/rds.tf in the consuming repo, which has its
# own RDSOSMetrics resource with its own import block) - a caller hitting that has to either
# import it into this address themselves (module.<path>.aws_cloudwatch_log_group.rds_os_metrics)
# or accept the log group's pre-existing (possibly shorter) retention by removing this resource.
resource "aws_cloudwatch_log_group" "rds_os_metrics" {
  name              = "RDSOSMetrics"
  retention_in_days = 365

  depends_on = [aws_iam_role_policy_attachment.rds_enhanced_monitoring]
}
