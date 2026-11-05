include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  proxy_vars = yamldecode(file(find_in_parent_folders("common.traefik.yaml")))
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/k8s/${local.proxy_vars.proxy}/helm"
}

dependencies {
  paths = [
    "${get_terragrunt_dir()}/../namespace",
    "${get_terragrunt_dir()}/../../eks/loadbalancercontroller",
    "${get_terragrunt_dir()}/../../karpenter/nodepool/main",
  ]
}

inputs = {
  namespace        = local.proxy_vars.namespace
  create_namespace = false
  deployment = {
    kind     = "Deployment"
    replicas = 2
  }
  log_level   = "DEBUG"
  access_logs = true

  # exposes the NLB (nlb_dns_name / nlb_zone_id) for the route53 records unit
  cluster_name = include.root.locals.ctx
}
