include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/ecr/repository"
}

inputs = {
  name         = "veyga/${basename(get_terragrunt_dir())}"
  keep_images  = 50
  mutable_tags = ["latest"]
  # veyga/exampleapp-ci: PR builds land here until their tests pass (app-ci)
  ci_repository = {
    enabled = true
  }
  tags = include.root.locals.aws.tags
}
