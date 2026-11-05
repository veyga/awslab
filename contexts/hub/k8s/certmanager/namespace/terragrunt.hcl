include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}


terraform {
  source = "${get_parent_terragrunt_dir()}/modules/k8s/namespace"
}

dependencies {
  paths = [
    "${get_terragrunt_dir()}/../../traefik/helm"
  ]
}

inputs = yamldecode(file(find_in_parent_folders("common.certmanager.yaml")))
