include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/route53/zone"
}

inputs = {
  zone_name = "awslab.io"
  tags      = include.root.locals.aws.tags
}
