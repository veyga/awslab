# role the runner-image GitHub workflow assumes (OIDC, no static keys) to push to ECR
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/iam/github-oidc-role"
}

dependency "ecr" {
  config_path = "${get_terragrunt_dir()}/../../ecr/gha-runner"
  mock_outputs = {
    arn = "arn:aws:ecr:us-east-1:000000000000:repository/mock"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  name = basename(get_terragrunt_dir())

  # main pushes latest, PRs (same-repo branches only; forks get no token) push sha tags
  subjects = [
    "repo:veygawslab/awslab:ref:refs/heads/main",
    "repo:veygawslab/awslab:pull_request",
  ]

  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EcrLogin"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "EcrPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:DescribeImages",
        ]
        Resource = dependency.ecr.outputs.arn
      },
    ]
  })

  tags = include.root.locals.aws.tags
}
