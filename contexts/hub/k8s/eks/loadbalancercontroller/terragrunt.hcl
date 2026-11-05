include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/k8s/eks/loadbalancercontroller"
}

dependencies {
  paths = [
    "${get_terragrunt_dir()}/../cluster"
  ]
}

dependency "vpc" {
  config_path = "${get_terragrunt_dir()}/../../../vpc"
  mock_outputs = {
    vpc_id = "asdf"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}


inputs = {
  cluster_name = include.root.locals.ctx
  vpc_id       = dependency.vpc.outputs.vpc_id
  aws_region   = include.root.locals.aws.region
  tags         = include.root.locals.aws.tags
  replicas     = 1
}
