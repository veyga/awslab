include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/k8s/eks/storageclass"
}

dependencies {
  paths = [
    "${get_terragrunt_dir()}/../cluster"
  ]
}

inputs = {
  ebs  = true
  tags = {}
  # running into issues provisioning with tags, whatever for this project
}
