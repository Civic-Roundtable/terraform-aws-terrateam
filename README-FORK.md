# Civic Roundtable fork

This is a fork of [terrateamio/terraform-aws-terrateam](https://github.com/terrateamio/terraform-aws-terrateam),
forked from commit `4e53bbb44961ee4f3ef7760923dc184446948341` (the upstream repo has no tagged
releases).

## Why this fork exists

`iam.tf` hardcoded `arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy` -
a commercial-partition (`aws`) ARN - when attaching the ECS task execution role's managed
policy. AWS-managed policies are partition-specific (`aws` vs `aws-us-gov` vs `aws-cn`), so this
attachment fails outright when the module is applied in AWS GovCloud (`aws-us-gov`), since that
partition doesn't recognize a commercial-partition ARN as the same policy.

This fork's only change: that ARN is now built from `data.aws_partition.current.partition`
instead of hardcoded, so it resolves correctly in whichever partition the module is deployed to.
Checked the rest of the module for other hardcoded partition-specific ARNs at fork time - this
was the only one.

Used from [Civic-Roundtable/devops](https://github.com/Civic-Roundtable/devops) by
`tf-modules/terrateam/terrateam-self-hosted-aws`, which deploys both a GovCloud and a commercial
Terrateam instance from the same module - see that repo for context.

### Second patch: `enable_https` instead of inferring from `acm_certificate_arn != null`

Upstream decides whether to create the HTTPS listener (`aws_lb_listener.https`) and its security
group rule by checking `var.acm_certificate_arn != null` in each resource's `count`. The consuming
module creates its ACM certificate in the same apply (via `terraform-aws-modules/acm/aws`) and
passes that module's output straight in, so on a first apply the ARN doesn't exist yet and is
unknown at plan time - and Terraform refuses to let a resource's `count` depend on an unknown
value ("Invalid count argument"), even though the caller knows statically it will always be
non-null. Added an explicit `enable_https` bool (default `false`, matching the old default
behavior) for `count` to key off instead; `acm_certificate_arn` is now only read for its actual
value (`certificate_arn = var.acm_certificate_arn`), never for a plan-time cardinality decision.
Callers that already pass `acm_certificate_arn` need to also pass `enable_https = true`.

## Maintaining this fork

Pinned by commit (not a branch or release) in the consuming module, same as upstream's own
convention. To pull in an upstream change: diff the target upstream commit against this fork's
base (`4e53bbb4...`), re-apply both patches above on top (checking `iam.tf` for the partition ARN
and `alb.tf`/`security_groups.tf`/`variables.tf` for the `enable_https` flag), re-check for new
hardcoded partition-specific ARNs, then update the pinned ref in
`tf-modules/terrateam/terrateam-self-hosted-aws/terrateam.tf`.
