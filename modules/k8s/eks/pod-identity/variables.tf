variable "name" {
  description = "IAM role name"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster the association lives in"
  type        = string
}

variable "namespace" {
  description = "namespace of the service account"
  type        = string
}

variable "service_account" {
  description = "service account to create and associate with the role"
  type        = string
}

variable "policy_arns" {
  description = "IAM policies attached to the role, keyed by a static name"
  type        = map(string)
}

variable "tags" {
  description = "aws tags"
  type        = map(string)
}
