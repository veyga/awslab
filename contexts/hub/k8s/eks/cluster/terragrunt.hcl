include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/k8s/eks/cluster"
}

dependency "vpc" {
  config_path = "${get_terragrunt_dir()}/../../../vpc"
  mock_outputs = {
    vpc_id          = "asdf"
    private_subnets = []
    intra_subnets   = []
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}


locals {
  ctx = include.root.locals.ctx
}

inputs = {
  eks_version = "1.36"
  name        = local.ctx
  vpc = {
    id              = dependency.vpc.outputs.vpc_id
    private_subnets = dependency.vpc.outputs.private_subnets
    intra_subnets   = dependency.vpc.outputs.intra_subnets
  }
  kubeconfig_out  = "${get_parent_terragrunt_dir()}/${local.ctx}.yaml"
  n_managed_nodes = 2
  tags            = include.root.locals.aws.tags
  addon_versions = {
    kube-proxy             = "latest"
    coredns                = "latest"
    vpc-cni                = "latest"
    eks-pod-identity-agent = "latest"
    aws-ebs-csi-driver     = "latest"
  }
}
