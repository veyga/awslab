variable "namespace" {
  description = "namespace for the controller"
  type        = string
}

variable "release_name" {
  description = "helm release name; the controller service account is <release_name>-gha-rs-controller"
  type        = string
  default     = "arc"
}

variable "chart_version" {
  description = "gha-runner-scale-set-controller chart version (keep in sync with the scale sets)"
  type        = string
}

variable "replicas" {
  description = "controller replicas"
  type        = number
  default     = 1
}

variable "log_level" {
  description = "controller log level (debug, info, warn, error)"
  type        = string
  default     = "info"
}

variable "node_selector" {
  description = "node selector for the controller pods"
  type        = map(string)
  default     = {}
}

variable "tolerations" {
  description = "tolerations for the controller pods"
  type = list(object({
    key      = string
    operator = optional(string, "Equal")
    value    = optional(string)
    effect   = optional(string, "NoSchedule")
  }))
  default = []
}
