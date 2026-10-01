# Civic Roundtable fork

Fork of [terrateamio/terraform-aws-terrateam](https://github.com/terrateamio/terraform-aws-terrateam),
used by [Civic-Roundtable/devops](https://github.com/Civic-Roundtable/devops)'s
`tf-modules/terrateam/terrateam-self-hosted-aws`. Patches on top of upstream, pinned by commit
(neither repo has tagged releases) - see each commit's own message for details:

- `2a38286` - partition-aware ARN for the ECS task execution role's managed policy (GovCloud fix).
- `6502d14` - `enable_https` flag instead of inferring HTTPS from `acm_certificate_arn != null`.
- `39d5b7c` - RDS/CloudWatch compliance hardening (customer-managed KMS, `gp3`, enhanced
  monitoring, `pgaudit`) to match this org's Vanta/Security Hub baseline. Everything it added is
  a variable defaulting to upstream's original behavior (unset `storage_type`, no CloudWatch log
  exports, monitoring off, `database_insights_mode = "standard"`, no extra parameter group
  entries) - the consuming repo's `terrateam.tf` passes the hardened values explicitly.
- `alb_deletion_protection` variable for the ALB's `enable_deletion_protection` (Security Hub
  ELB.6), defaulting to upstream's `false`; the consuming repo passes `true`.
- `alb_drop_invalid_header_fields` (Security Hub ELB.4), `alb_access_logs_enabled`/`_bucket`/
  `_prefix` (ELB.5), and `alb_http_listener` (turns off the port-80 listener and its ingress
  rule, for HTTPS-only) - all defaulting to upstream's behavior; the consuming repo passes the
  hardened values.
- `container_user` for the task definition's `user` (Security Hub ECS.20), defaulting to unset
  like upstream; the consuming repo passes the image's non-root `terrat` user.
- `db_copy_tags_to_snapshot` variable for the RDS instance's `copy_tags_to_snapshot` (Security
  Hub RDS.17), defaulting to upstream's `false`; the consuming repo passes `true`.

When bumping the pinned ref: diff the target upstream commit against this fork's base
(`4e53bbb4`), re-apply the patches above on top if the files they touch changed, and re-check for
new hardcoded partition-specific ARNs.
