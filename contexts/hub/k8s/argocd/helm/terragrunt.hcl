include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  argo_vars  = yamldecode(file(find_in_parent_folders("common.argocd.yaml")))
  proxy_vars = yamldecode(file(find_in_parent_folders("common.traefik.yaml")))
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/k8s/argocd/helm"
}

dependencies {
  paths = [
    "${get_terragrunt_dir()}/../namespace",
    "${get_terragrunt_dir()}/../../traefik/helm",
    "${get_terragrunt_dir()}/../../certmanager/issuers",
    "${get_terragrunt_dir()}/../../karpenter/nodepool/main",
  ]
}

inputs = {
  namespace        = local.argo_vars.namespace
  create_namespace = false
  domain           = local.argo_vars.domain

  ingress = {
    enabled     = true
    class       = local.proxy_vars.ingressclass
    annotations = {}
    cert_issuer = "clusterissuer-prod"
  }

  node_selector = {
    "karpenter.sh/nodepool" = "main"
  }
}
