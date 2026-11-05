locals {
  ctx               = basename(get_terragrunt_dir())
  cluster_full_name = "hub"
  arch              = "amd"
  aws_tags = {
    "environment" = "infrastructure"
    "cluster"     = basename(get_terragrunt_dir())
  }
}
