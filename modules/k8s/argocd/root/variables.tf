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

variable "org_url" {
  description = "URL prefix the repo_token is used for as a credential template (every repo in the org)"
  type        = string
  default     = "https://github.com/veygawslab"
}

variable "app_repos" {
  description = "app repos whose deploy/application.yaml (an ApplicationSet) the root Application syncs"
  type        = list(string)

  validation {
    condition     = length(var.app_repos) > 0
    error_message = "list at least one app repo"
  }
}

variable "target_revision" {
  description = "branch the root Application tracks in every app repo"
  type        = string
  default     = "main"
}
