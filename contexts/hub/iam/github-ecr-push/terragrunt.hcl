# role the runner-image GitHub workflow assumes (OIDC, no static keys) for ECR
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/iam/github-oidc-role"
}

inputs = {
  name = basename(get_terragrunt_dir())

  # main pushes latest, PRs (same-repo branches only; forks get no token) push sha tags
  subjects = [
    "repo:veygawslab/awslab:ref:refs/heads/main",
    "repo:veygawslab/awslab:pull_request",
  ]

  # full ECR access (every action, every repository in the account)
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EcrFullAccess"
        Effect   = "Allow"
        Action   = ["ecr:*"]
        Resource = "*"
      },
    ]
  })

  tags = include.root.locals.aws.tags
}
