include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/k8s/karpenter/helm"
}


dependency "eks" {
  config_path = "${get_terragrunt_dir()}/../../eks/cluster"
  mock_outputs = {
    cluster_name         = "asdf"
    cluster_endpoint     = "asdf"
    karpenter_queue_name = "asdf"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  karpenter_version    = "1.6.2"
  cluster_name         = dependency.eks.outputs.cluster_name
  cluster_endpoint     = dependency.eks.outputs.cluster_endpoint
  karpenter_queue_name = dependency.eks.outputs.karpenter_queue_name
  replicas             = 2
}

