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
    "${get_terragrunt_dir()}/../../../../ecr/gharunner",
  ]
}

dependency "pod_identity" {
  config_path = "${get_terragrunt_dir()}/../../pod-identity"
  mock_outputs = {
    service_account_name = "gha-runner"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

# the runner image's repository (images/gha-runner is pushed there)
dependency "ecr" {
  config_path = "${get_terragrunt_dir()}/../../../../ecr/gharunner"
  mock_outputs = {
    repository_url = "000000000000.dkr.ecr.us-east-1.amazonaws.com/veyga/gharunner"
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

  # our image (images/gha-runner, built by .github/workflows/runner-image.yml): the stock
  # runner plus aws/helm/kubectl/terraform/uv/... `latest` is pulled on every pod start.
  # If a bad latest breaks the runners, point this back at ghcr.io/actions/actions-runner.
  runner_image = "${dependency.ecr.outputs.repository_url}:latest"

  # ECR push/pull for every job (Pod Identity)
  runner_service_account = dependency.pod_identity.outputs.service_account_name

  # docker daemon sidecar, for job containers (`container:`) and image builds
  container_mode = "dind"

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
