# runner image for the ARC scale sets; built from images/gha-runner by .github/workflows/runner-image.yml
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/ecr/repository"
}

inputs = {
  name        = basename(get_terragrunt_dir())
  keep_images = 20
  # main pushes overwrite latest; PR builds push immutable <short sha> tags
  mutable_tags = ["latest"]
  tags         = include.root.locals.aws.tags
}
