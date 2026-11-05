include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/k8s/certmanager/helm"
}

dependencies {
  paths = [
    "${get_terragrunt_dir()}/../namespace"
  ]
}

inputs = merge(
  yamldecode(file(find_in_parent_folders("common.certmanager.yaml"))),
  {
    create_namespace = false
    install_crds     = true
  }
)
