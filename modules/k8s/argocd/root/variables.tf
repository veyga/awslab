variable "namespace" {
  description = "namespace Argo CD runs in"
  type        = string
}

variable "repo_url" {
  description = "gitops repo the root Application syncs"
  type        = string
}

variable "repo_token" {
  description = "GitHub token with read access (Contents: read) to the gitops repo"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.repo_token) > 0
    error_message = "repo_token is empty: set ARGOCD_GITOPS_TOKEN (e.g. in .env)"
  }
}

variable "target_revision" {
  description = "branch/tag the root Application tracks"
  type        = string
  default     = "main"
}

variable "root_path" {
  description = "directory in the gitops repo holding the root manifests"
  type        = string
  default     = "root"
}
