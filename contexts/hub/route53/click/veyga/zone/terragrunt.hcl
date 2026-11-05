include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/route53/zone"
}

dependency "domain" {
  config_path = "${get_terragrunt_dir()}/../domain"
  mock_outputs = {
    hosted_zone_id = "Z00000000000000000MOCK"
  }
  # no mocks for plan/apply: importing a fake zone id would fail
  mock_outputs_allowed_terraform_commands = ["init", "validate"]
}

inputs = {
  zone_name = "veyga.click"
  tags      = include.root.locals.aws.tags
}

# Registering veyga.click (../domain) creates this zone and points the domain at it,
# so adopt it rather than creating a second, undelegated zone
generate "import" {
  path      = "import.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
  import {
    to = aws_route53_zone.main
    id = "${dependency.domain.outputs.hosted_zone_id}"
  }
  EOF
}
