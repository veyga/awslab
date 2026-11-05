include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  arc_vars = yamldecode(file(find_in_parent_folders("common.gha-runners.yaml")))
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/k8s/gha-runners/controller"
}

dependencies {
  paths = [
    "${get_terragrunt_dir()}/../namespace",
    "${get_terragrunt_dir()}/../../karpenter/nodepool/main",
  ]
}

inputs = {
  namespace     = local.arc_vars.namespace
  chart_version = local.arc_vars.chart_version
  replicas      = 1

  # the controller runs on the general purpose nodepool, never on runner nodes
  node_selector = {
    "karpenter.sh/nodepool" = "main"
  }
}
