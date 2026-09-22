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

## Maintaining this fork

Pinned by commit (not a branch or release) in the consuming module, same as upstream's own
convention. To pull in an upstream change: diff the target upstream commit against this fork's
base (`4e53bbb4...`), re-apply the partition-ARN patch on top if `iam.tf` changed, re-check for
new hardcoded partition-specific ARNs, then update the pinned ref in
`tf-modules/terrateam/terrateam-self-hosted-aws/terrateam.tf`.
