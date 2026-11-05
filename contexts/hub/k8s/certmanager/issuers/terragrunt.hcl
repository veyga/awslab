include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  proxy_vars = yamldecode(file(find_in_parent_folders("common.traefik.yaml")))
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/k8s/certmanager/issuers"
}

dependencies {
  paths = [
    "${get_terragrunt_dir()}/../helm"
  ]
}

inputs = {
  ingressclass = local.proxy_vars.ingressclass
}
