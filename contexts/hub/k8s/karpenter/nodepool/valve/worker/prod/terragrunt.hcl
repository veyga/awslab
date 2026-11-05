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

# CONF idc valve-worker-prod nodepool
inputs = {
  name                     = "valve-worker-${local.env}"
  disruption_percentage    = "80%"
  consolidate_after        = "10s"
  termination_grace_period = "1h0m0s"
  node_class               = "${local.env}-worker"

  capacity_types          = ["spot"]
  instance_categories     = ["c"]
  min_instance_generation = 6 # right now this cant be > 6 it seems (nodes dont get provisioned)
  instance_sizes          = ["xlarge"]

  taints = [
    {
      key   = "valve-worker-${local.env}-taint"
      value = "valve-worker-${local.env}-value"
    },
  ]

  eks_auto = false
  labels = {
    "netx/promstack" = true
  }
}
