include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "."
}

dependencies {
  paths = [
    "${get_terragrunt_dir()}/dev",
    "${get_terragrunt_dir()}/staging",
    "${get_terragrunt_dir()}/prod",
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
