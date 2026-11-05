include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "."
}

dependencies {
  paths = [
    "${get_terragrunt_dir()}/netx",
    "${get_terragrunt_dir()}/iiif",
    "${get_terragrunt_dir()}/valve/worker",
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


