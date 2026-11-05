include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "."
}

dependencies {
  paths = [
    "${get_terragrunt_dir()}/us-west-2a",
    "${get_terragrunt_dir()}/us-west-2b",
    "${get_terragrunt_dir()}/us-west-2c",
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
