include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/route53/domain"
}

# Registering also creates the veyga.click hosted zone (no separate zone unit needed).
# Contact details live in the gitignored domain-contact.yaml (see domain-contact.example.yaml):
# this repo is public.
inputs = {
  domain_name = "veyga.click"
  contact     = yamldecode(file("${get_repo_root()}/domain-contact.yaml"))
  tags        = include.root.locals.aws.tags
}
