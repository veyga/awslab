variable "name" {
  description = "name for cluster"
  type        = string
}

variable "eks_version" {
  description = "EKS version"
  type        = string
}

variable "vpc" {
  description = "vpc info"
  type = object({
    id              = string
    private_subnets = list(string)
    intra_subnets   = list(string)
  })
}

variable "kubeconfig_out" {
  description = "where to write the resulting kubeconfig"
  type        = string
}

variable "tags" {
  description = "aws tags"
  type        = map(string)
}

variable "n_managed_nodes" {
  description = <<EOT
  number of managed nodes, for hosting karpenter
  This should not be changed after provisioning
  EOT
  type        = number

  validation {
    condition     = var.n_managed_nodes >= 2
    error_message = "The number of managed nodes must be at least 2"
  }
}

variable "addon_versions" {
  description = "versions for addons"
  type        = map(string)
}
