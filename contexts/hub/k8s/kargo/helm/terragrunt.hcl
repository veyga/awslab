include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  kargo_vars = yamldecode(file(find_in_parent_folders("common.kargo.yaml")))
  argo_vars  = yamldecode(file(find_in_parent_folders("common.argocd.yaml")))
  proxy_vars = yamldecode(file(find_in_parent_folders("common.traefik.yaml")))
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/k8s/kargo/helm"
}

dependencies {
  paths = [
    "${get_terragrunt_dir()}/../namespace",
    "${get_terragrunt_dir()}/../../argocd/helm",
    "${get_terragrunt_dir()}/../../traefik/helm",
    "${get_terragrunt_dir()}/../../certmanager/issuers",
    "${get_terragrunt_dir()}/../../karpenter/nodepool/main",
  ]
}

inputs = {
  namespace     = local.kargo_vars.namespace
  chart_version = local.kargo_vars.chart_version
  domain        = local.kargo_vars.domain

  ingress = {
    class       = local.proxy_vars.ingressclass
    cert_issuer = "clusterissuer-prod"
  }

  argocd = {
    namespace = local.argo_vars.namespace
    url       = "https://${local.argo_vars.domain}"
  }

  # same fine-grained PAT Argo CD uses (contexts/hub/k8s/argocd/root): veygawslab/gitops,
  # "Contents: read and write". Kept in the local .env file
  gitops_repo = {
    url   = local.argo_vars.repo_url
    token = get_env("ARGOCD_GITOPS_TOKEN", "")
  }

  node_selector = {
    "karpenter.sh/nodepool" = "main"
  }
}
