variable "efs" {
  type = object({
    id = optional(string)
  })
}

variable "ebs" {
  type = bool
}

variable "eks_auto" {
  description = "if this cluster is using EKS auto mode"
  type        = bool
}

variable "tags" {
  description = "Tags to apply to provisioned AWS resources"
  type        = map(string)
}
