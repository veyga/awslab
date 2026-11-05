variable "karpenter_version" {
  description = "chart version"
  type        = string
}

variable "cluster_name" {
  description = "name of the eks cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "endpoint for the cluster"
  type        = string
}

variable "karpenter_queue_name" {
  description = "sqs queue name for karpenter"
  type        = string
}

variable "replicas" {
  description = <<EOT
  number of replicas
  This should be <= the number of nodes in the managed node group
  EOT
  type        = number
}
