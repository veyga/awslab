include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/ecr/repository"
}

inputs = {
  name = "veyga/charts/${basename(get_terragrunt_dir())}"
  # chart versions are immutable and never expire: apps may pin any old version
  keep_images = null
  tags        = include.root.locals.aws.tags
}
