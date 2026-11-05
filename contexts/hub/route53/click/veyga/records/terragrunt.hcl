include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/route53/records"
}

dependencies {
  paths = [
    "${get_terragrunt_dir()}/../zone"
  ]
}

dependency "traefik" {
  config_path = "${get_terragrunt_dir()}/../../../../k8s/traefik/helm"
  mock_outputs = {
    nlb_dns_name = "traefik"
    nlb_zone_id  = "traefik"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

# every *.veyga.click hostname goes to traefik, which routes by Host
inputs = {
  zone_name = "veyga.click"
  alias_records = {
    wildcard = {
      name                   = "*.veyga.click"
      target_dns_name        = dependency.traefik.outputs.nlb_dns_name
      target_zone_id         = dependency.traefik.outputs.nlb_zone_id
      record_type            = "A"
      evaluate_target_health = true
    }
  }
}
