# Civic Roundtable fork

Fork of [terrateamio/terraform-aws-terrateam](https://github.com/terrateamio/terraform-aws-terrateam),
used by [Civic-Roundtable/devops](https://github.com/Civic-Roundtable/devops)'s
`tf-modules/terrateam/terrateam-self-hosted-aws`. Two patches on top of upstream, pinned by
commit (neither repo has tagged releases) - see each commit's own message for details:

- `2a38286` - partition-aware ARN for the ECS task execution role's managed policy (GovCloud fix).
- `6502d14` - `enable_https` flag instead of inferring HTTPS from `acm_certificate_arn != null`.

When bumping the pinned ref: diff the target upstream commit against this fork's base
(`4e53bbb4`), re-apply both patches on top if the files they touch changed, and re-check for new
hardcoded partition-specific ARNs.
