include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/vpc"
}

inputs = {
  vpc_cidr = "10.51.0.0/16"
  name     = include.root.locals.ctx
  public_subnet_tags = { }
  private_subnet_tags = { }
  #   "kubernetes.io/role/elb" = 1
  # }
  # private_subnet_tags = {
  #   "kubernetes.io/role/internal-elb" = 1
  #   "karpenter.sh/discovery"          = include.root.locals.ctx
  # }
  aws_tags = include.root.locals.aws.tags
}

