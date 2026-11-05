variable "namespace" {
  description = "Kubernetes namespace for Kargo (created by the namespace context)"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster Kargo runs in (for the controller's pod identity association)"
  type        = string
}

variable "tags" {
  description = "aws tags"
  type        = map(string)
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

variable "git" {
  description = "GitHub token Kargo uses for every repo matching repo_url_regex: read on app repos, read/write (Contents) on the gitops repo"
  type = object({
    repo_url_regex = string
    token          = string
  })
  sensitive = true

  validation {
    condition     = length(var.git.token) > 0
    error_message = "git.token is empty: set ARGOCD_GITOPS_TOKEN (e.g. in .env)"
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
