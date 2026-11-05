include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/k8s/karpenter/nodepool"
}

locals {
  node_class = basename(get_terragrunt_dir())
}

dependencies {
  paths = [
    "${get_terragrunt_dir()}/../../../nodeclass/${local.node_class}"
  ]
}

inputs = {
  name = "netx-${local.node_class}"

  disruption_percentage    = "10%"
  consolidate_after        = "5m"
  termination_grace_period = "24h0m0s"

  node_class = local.node_class

  capacity_types          = ["spot"]
  instance_categories     = ["m"]
  min_instance_generation = 5
  instance_sizes          = ["xlarge", "2xlarge"]

  eks_auto = false
  labels = {
    "netx/promstack" = true
  }
}

