variable "name" {
  description = "IAM role name"
  type        = string
}

variable "create_oidc_provider" {
  description = "create the account's IAM OIDC provider for GitHub Actions (false = look up an existing one)"
  type        = bool
  default     = true
}

variable "subjects" {
  description = "allowed `sub` claims (StringLike), e.g. repo:<org>/<repo>:ref:refs/heads/main"
  type        = list(string)
}

variable "policy_json" {
  description = "inline policy attached to the role"
  type        = string
}

variable "tags" {
  description = "aws tags"
  type        = map(string)
}
