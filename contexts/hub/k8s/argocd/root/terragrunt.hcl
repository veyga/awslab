# app-of-apps: the root Application syncs each app repo's deploy/application.yaml.
# veygawslab/gitops (repo_url, credentials only) holds just what Kargo renders
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

  # every app deployed through Argo CD + Kargo: add its repo here
  app_repos = [
    "https://github.com/veygawslab/exampleapp.git",
    "https://github.com/veygawslab/devops-task.git", # helloapp
  ]

  # fine-grained PAT, resource owner veygawslab, repo veygawslab/gitops,
  # "Contents: read and write" (Argo CD reads; Kargo, contexts/hub/k8s/kargo/helm, pushes).
  # Also needs "Contents: read" on every app repo (e.g. veygawslab/exampleapp): Argo CD and
  # Kargo use it for the whole org (creds-github-org, repo-github-org)
  # this I'm keeping locally in an .env file
  # in reality this would be saved in vault/secrets manager and pulled
  # down during the 'apply'
  repo_token = get_env("ARGOCD_GITOPS_TOKEN", "")
}
