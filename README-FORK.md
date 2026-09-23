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

When bumping the pinned ref: diff the target upstream commit against this fork's base
(`4e53bbb4`), re-apply the patches above on top if the files they touch changed, and re-check for
new hardcoded partition-specific ARNs.
