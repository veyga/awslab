# this allows me to specificy TG dependencies on a higher level dir
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "."
}

dependencies {
  paths = [
    "${get_terragrunt_dir()}/main",
    "${get_terragrunt_dir()}/worker",
  ]
}

generate "noop" {
  path      = "noop.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
  resource "null_resource" "noop" {
    triggers = {
      path = "."
    }
  }
  EOF
}
