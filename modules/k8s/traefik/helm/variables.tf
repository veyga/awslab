variable "traefik_version" {
  description = "traefik imagee"
  type        = string
  default     = "v3.6.7"
}

variable "namespace" {
  description = "namespace for the controller"
  type        = string
}

variable "create_namespace" {
  description = "auto create namespace"
  type        = bool
}

variable "image_override" {
  description = "use custom traefik image"
  type        = map(string)
  default     = null
}

variable "deployment" {
  description = "type of deployment"
  type = object({
    kind     = string
    replicas = optional(number)
  })
}

variable "service_override" {
  description = "override service configuration"
  type = object({
    type                  = string
    annotations           = optional(map(string), {})
    externalTrafficPolicy = optional(string)
    internalTrafficPolicy = optional(string)
  })
  default = null
}

variable "ports_override" {
  description = "override ports configuration for NodePort"
  type = map(object({
    port     = number
    nodePort = optional(number)
  }))
  default = null
}

variable "log_level" {
  description = "general log level"
  type        = string
  default     = "INFO"
}

variable "log_format" {
  description = "log format"
  type        = string
  default     = "common"

  validation {
    condition     = contains(["common", "json"], var.log_format)
    error_message = "Log format must be one of: common, genericCLF, json."
  }
}

variable "access_logs" {
  description = "enable access logs"
  type        = bool
  default     = false
}

variable "access_logs_format" {
  description = "enable access logs"
  type        = string
  default     = "common"

  validation {
    condition     = contains(["common", "genericCLF", "json"], var.access_logs_format)
    error_message = "Log format must be one of: common, genericCLF, json."
  }
}

variable "persist_logs" {
  type    = bool
  default = false
}
