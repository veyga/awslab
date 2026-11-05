# general purpose nodepool for spot nodes
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/k8s/karpenter/nodepool"
}

locals {
  node_class = "main"
}

dependencies {
  paths = [
    "${get_terragrunt_dir()}/../../nodeclass/${local.node_class}"
  ]
}

inputs = {
  name                     = basename(get_terragrunt_dir())
  disruption_percentage    = "80%"
  consolidate_after        = "10s"
  termination_grace_period = "1h0m0s"
  node_class               = local.node_class

  capacity_types          = ["spot"]
  instance_categories     = ["c", "m", "t"]
  min_instance_generation = 3
  instance_sizes          = ["medium"]

  taints = [
    {
      key   = "runner-taint"
      value = "runner-value"
    },
  ]
}
