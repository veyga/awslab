variable "namespace" {
  description = "Kubernetes namespace for Kargo (created by the namespace context)"
  type        = string
}

variable "chart_version" {
  description = "akuity kargo chart version"
  type        = string
}

variable "domain" {
  description = "hostname Kargo's API/UI is served on, e.g. kargo.veyga.click"
  type        = string
}

variable "ingress" {
  description = "Ingress configuration"
  type = object({
    class       = string
    cert_issuer = string
  })
}

variable "argocd" {
  description = "the Argo CD Kargo promotes through"
  type = object({
    namespace = string
    url       = string
  })
}

variable "gitops_repo" {
  description = "gitops repo Kargo promotes by committing to, with a GitHub token that can push to it (Contents: read and write)"
  type = object({
    url   = string
    token = string
  })
  sensitive = true

  validation {
    condition     = length(var.gitops_repo.token) > 0
    error_message = "gitops_repo.token is empty: set ARGOCD_GITOPS_TOKEN (e.g. in .env)"
  }
}

variable "node_selector" {
  description = "node selector for all Kargo components"
  type        = map(string)
  default     = {}
}

variable "api" {
  description = "Kargo API server configuration"
  type = object({
    replicas = number
  })
  default = {
    replicas = 1
  }
}

variable "webhooks_server" {
  description = "Kargo (Kubernetes admission) webhooks server configuration"
  type = object({
    replicas = number
  })
  default = {
    replicas = 1
  }
}
