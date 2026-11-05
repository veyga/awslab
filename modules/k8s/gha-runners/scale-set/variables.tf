variable "name" {
  description = "scale set name; this is the `runs-on` label workflows use"
  type        = string
}

variable "namespace" {
  description = "namespace for the listener and runner pods"
  type        = string
}

variable "chart_version" {
  description = "gha-runner-scale-set chart version (must match the controller)"
  type        = string
}

variable "controller" {
  description = "the ARC controller this scale set registers with (outputs of ../controller)"
  type = object({
    namespace            = string
    service_account_name = string
  })
}

variable "github_config_url" {
  description = <<EOT
  where runners register: an org (https://github.com/<org>, every repo in the org) or a
  single repo (https://github.com/<owner>/<repo>). User accounts only support the latter.
  EOT
  type        = string
}

variable "github_token" {
  description = "PAT for registering runners. Fine-grained: org permission \"Self-hosted runners: read and write\" (org url) or repo \"Administration: read and write\" (repo url). Ignored when github_app is set"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_app" {
  description = "GitHub App credentials, preferred over a PAT"
  type = object({
    app_id          = string
    installation_id = string
    private_key     = string
  })
  default   = null
  sensitive = true
}

variable "min_runners" {
  description = "idle runners kept warm (0 = scale to zero)"
  type        = number
  default     = 0
}

variable "max_runners" {
  description = "max concurrent runners"
  type        = number
  default     = 5
}

variable "runner_image" {
  description = "runner container image"
  type        = string
  default     = "ghcr.io/actions/actions-runner:2.336.0"
}

variable "runner_resources" {
  description = "runner pod resources; must fit on a node of the runner nodepool"
  type = object({
    cpu          = string
    memory       = string
    memory_limit = string
  })
  default = {
    cpu          = "1"
    memory       = "2Gi"
    memory_limit = "3Gi"
  }
}

variable "listener_node_selector" {
  description = "node selector for the listener pod"
  type        = map(string)
  default     = {}
}

variable "listener_tolerations" {
  description = "tolerations for the listener pod"
  type = list(object({
    key      = string
    operator = optional(string, "Equal")
    value    = optional(string)
    effect   = optional(string, "NoSchedule")
  }))
  default = []
}

variable "runner_node_selector" {
  description = "node selector for the runner pods"
  type        = map(string)
  default     = {}
}

variable "runner_tolerations" {
  description = "tolerations for the runner pods"
  type = list(object({
    key      = string
    operator = optional(string, "Equal")
    value    = optional(string)
    effect   = optional(string, "NoSchedule")
  }))
  default = []
}
