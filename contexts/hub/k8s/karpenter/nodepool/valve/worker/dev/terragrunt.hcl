include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/k8s/karpenter/nodepool"
}

locals {
  env = basename(get_terragrunt_dir())
}

dependencies {
  paths = [
    "${get_terragrunt_dir()}/../../../../nodeclass/${local.env}-worker"
  ]
}

# CONF idc valve-worker-dev nodepool
inputs = {
  name                     = "valve-worker-${local.env}"
  disruption_percentage    = "80%"
  consolidate_after        = "10s"
  termination_grace_period = "1h0m0s"
  node_class               = "${local.env}-worker"

  capacity_types          = ["spot"]
  instance_categories     = ["c", "m", "t"]
  min_instance_generation = 3
  instance_sizes          = ["medium"]

  taints = [
    {
      key   = "valve-worker-${local.env}-taint"
      value = "valve-worker-${local.env}-value"
    },
  ]

  eks_auto = false
  labels = {
    "netx/promstack" = false
  }
}
