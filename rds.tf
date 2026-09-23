resource "aws_db_subnet_group" "this" {
  name_prefix = "${var.name}-"
  subnet_ids  = var.private_subnet_ids
  tags        = var.tags
}

# family must track the major version of var.db_engine_version (e.g. "postgres14" for "14.18").
# Parameters default to none (var.db_parameters), matching the engine family's default group.
resource "aws_db_parameter_group" "this" {
  name_prefix = "${var.name}-"
  family      = "postgres${split(".", var.db_engine_version)[0]}"

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = var.tags
}

# Only needed when enhanced monitoring is on (var.db_monitoring_interval > 0); AWS default is off.
data "aws_iam_policy_document" "rds_enhanced_monitoring_assume" {
  count = var.db_monitoring_interval > 0 ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = var.db_monitoring_interval > 0 ? 1 : 0

  name_prefix        = "${var.name}-rds-monitoring-"
  assume_role_policy = data.aws_iam_policy_document.rds_enhanced_monitoring_assume[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count = var.db_monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.rds_enhanced_monitoring[0].name
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
  storage_type          = var.db_storage_type
  allocated_storage     = 20
  max_allocated_storage = 100
  kms_key_id            = var.kms_key_id

  enabled_cloudwatch_logs_exports       = var.db_enabled_cloudwatch_logs_exports
  performance_insights_enabled          = true
  performance_insights_retention_period = var.db_performance_insights_retention_period
  performance_insights_kms_key_id       = var.kms_key_id
  monitoring_interval                   = var.db_monitoring_interval
  monitoring_role_arn                   = var.db_monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null
  database_insights_mode                = var.db_database_insights_mode

  multi_az                = var.db_multi_az
  backup_retention_period = var.db_backup_retention_period
  deletion_protection     = var.db_deletion_protection

  skip_final_snapshot       = var.db_skip_final_snapshot
  final_snapshot_identifier = var.db_skip_final_snapshot ? null : "${var.name}-final"

  tags = var.tags

  depends_on = [aws_iam_role_policy_attachment.rds_enhanced_monitoring]
}

# AWS auto-creates these when the corresponding export/enhanced-monitoring is enabled, but with
# no expiry - creating them ourselves first gets our own retention setting applied instead. Only
# created when the thing that would populate them is actually enabled.
resource "aws_cloudwatch_log_group" "rds_postgresql" {
  count = contains(var.db_enabled_cloudwatch_logs_exports, "postgresql") ? 1 : 0

  name              = "/aws/rds/instance/${aws_db_instance.this.identifier}/postgresql"
  retention_in_days = var.db_log_retention_in_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "rds_upgrade" {
  count = contains(var.db_enabled_cloudwatch_logs_exports, "upgrade") ? 1 : 0

  name              = "/aws/rds/instance/${aws_db_instance.this.identifier}/upgrade"
  retention_in_days = var.db_log_retention_in_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "rds_os_metrics" {
  count = var.db_monitoring_interval > 0 ? 1 : 0

  name              = "RDSOSMetrics"
  retention_in_days = var.db_log_retention_in_days

  depends_on = [aws_iam_role_policy_attachment.rds_enhanced_monitoring]
}
