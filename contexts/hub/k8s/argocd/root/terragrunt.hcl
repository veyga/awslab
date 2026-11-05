# app-of-apps: the root Application syncs root/ in veygawslab/gitops
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  argo_vars = yamldecode(file(find_in_parent_folders("common.argocd.yaml")))
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/k8s/argocd/root"
}

dependencies {
  paths = [
    "${get_terragrunt_dir()}/../helm"
  ]
}

inputs = {
  namespace = local.argo_vars.namespace
  repo_url  = local.argo_vars.repo_url

  # fine-grained PAT, resource owner veygawslab, repo veygawslab/gitops,
  # "Contents: read" (Kargo will later need read and write)
  # this I'm keeping locally in an .env file
  # in reality this would be saved in vault/secrets manager and pulled
  # down during the 'apply'
  repo_token = get_env("ARGOCD_GITOPS_TOKEN", "")
}
