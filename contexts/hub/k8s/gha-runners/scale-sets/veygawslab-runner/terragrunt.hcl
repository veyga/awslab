# org-wide runners for every repo in github.com/veygawslab: `runs-on: veygawslab-runner`
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  arc_vars = yamldecode(file(find_in_parent_folders("common.gha-runners.yaml")))
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/k8s/gha-runners/scale-set"
}

dependencies {
  paths = [
    "${get_terragrunt_dir()}/../../../karpenter/nodepool/runner",
  ]
}

dependency "pod_identity" {
  config_path = "${get_terragrunt_dir()}/../../pod-identity"
  mock_outputs = {
    service_account_name = "gha-runner"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "controller" {
  config_path = "${get_terragrunt_dir()}/../../controller"
  mock_outputs = {
    namespace            = "gha-runners"
    service_account_name = "arc-gha-rs-controller"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  name              = basename(get_terragrunt_dir())
  namespace         = local.arc_vars.namespace
  chart_version     = local.arc_vars.chart_version
  controller        = dependency.controller.outputs
  github_config_url = "https://github.com/veygawslab"

  # fine-grained PAT, resource owner veygawslab, with the organization permission
  # "Self-hosted runners: read and write"
  # this I'm keeping locally in an .env file
  # in reality this would be saved in vault/secrets manager and pulled
  # down during the 'apply'
  github_token = get_env("GHA_RUNNERS_GITHUB_TOKEN", "")

  # ECR push/pull for every job (Pod Identity)
  runner_service_account = dependency.pod_identity.outputs.service_account_name

  min_runners = 0
  max_runners = 5

  # the listener stays on the general purpose nodepool
  listener_node_selector = {
    "karpenter.sh/nodepool" = "main"
  }

  # only the job pods land on the (tainted, spot) runner nodepool
  runner_node_selector = {
    "karpenter.sh/nodepool" = "runner"
  }
  runner_tolerations = [
    {
      key   = "runner-taint"
      value = "runner-value"
    },
  ]
}
