# AWS access for the runner pods of every scale set: ECR push/pull via Pod Identity
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  arc_vars = yamldecode(file(find_in_parent_folders("common.gha-runners.yaml")))
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/k8s/eks/pod-identity"
}

dependencies {
  paths = [
    "${get_terragrunt_dir()}/../namespace",
    "${get_terragrunt_dir()}/../../eks/cluster",
  ]
}

inputs = {
  name            = "${include.root.locals.ctx}-gha-runner"
  cluster_name    = include.root.locals.ctx
  namespace       = local.arc_vars.namespace
  service_account = "gha-runner"

  # push/pull to every repository, but no deleting repositories or changing their policies
  policy_arns = {
    ecr = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
  }

  tags = include.root.locals.aws.tags
}
