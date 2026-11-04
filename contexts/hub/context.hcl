locals {
  ctx               = basename(get_terragrunt_dir())
  cluster_full_name = "hub"
  arch              = "amd"
  aws_tags = {
    "environment" = "infrastructure"
    "product"     = "iiify"
    "cluster"     = basename(get_terragrunt_dir())
  }
}
