locals {
  oidc_host = "token.actions.githubusercontent.com"
}

# One OIDC provider per issuer per account. If another stack already created it,
# set create_oidc_provider = false.
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url            = "https://${local.oidc_host}"
  client_id_list = ["sts.amazonaws.com"]

  tags = var.tags
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 0 : 1
  url   = "https://${local.oidc_host}"
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn
}

# Assumed by GitHub Actions jobs (aws-actions/configure-aws-credentials);
# only the listed repo/ref subjects match
data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    # e.g. repo:veygawslab/awslab:ref:refs/heads/main
    condition {
      test     = "StringLike"
      variable = "${local.oidc_host}:sub"
      values   = var.subjects
    }
  }
}

resource "aws_iam_role" "main" {
  name                 = var.name
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  max_session_duration = 3600

  tags = var.tags
}

resource "aws_iam_role_policy" "main" {
  name   = var.name
  role   = aws_iam_role.main.id
  policy = var.policy_json
}
