variable "namespace" {
  description = "Kubernetes namespace for ArgoCD"
  type        = string
}

variable "create_namespace" {
  description = "Whether to create the namespace"
  type        = bool
}

variable "chart_version" {
  description = "argo-helm argo-cd chart version"
  type        = string
  default     = "10.4.1"
}

variable "domain" {
  type        = string
  description = "hostname Argo CD is served on, e.g. argo.veyga.click"
}

variable "ingress" {
  description = "Ingress configuration"
  type = object({
    enabled     = bool
    class       = string
    annotations = map(string)
    cert_issuer = string
  })
}

variable "node_selector" {
  description = "node selector for all Argo CD components"
  type        = map(string)
  default     = {}
}

variable "server" {
  description = "ArgoCD server configuration"
  type = object({
    replicas = number
  })
  default = {
    replicas = 1
  }
}

variable "repo_server" {
  description = "ArgoCD repo server configuration"
  type = object({
    replicas = number
  })
  default = {
    replicas = 1
  }
}

variable "controller" {
  description = "ArgoCD controller configuration"
  type = object({
    replicas = number
  })
  default = {
    replicas = 1
  }
}
