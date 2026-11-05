include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/k8s/karpenter/nodeclass"
}

dependencies {
  paths = [
    "${get_terragrunt_dir()}/../../helm"
  ]
}

dependency "eks" {
  config_path = "${get_terragrunt_dir()}/../../../eks/cluster"
  mock_outputs = {
    cluster_primary_security_group_id = "asdf"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "vpc" {
  config_path = "${get_terragrunt_dir()}/../../../../vpc"
  mock_outputs = {
    private_subnets = []
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  node_class_name   = basename(get_terragrunt_dir())
  cluster_name      = include.root.locals.ctx
  security_group_id = dependency.eks.outputs.cluster_primary_security_group_id
  subnets = [
    {
      id = dependency.vpc.outputs.private_subnets[1]
    }
  ]
  tags = merge(include.root.locals.aws.tags,
    {
      "created_by"  = "karpenter"
      "environment" = "production"
  })
  ami            = "al2023"
  root_volume_gb = 40
}
