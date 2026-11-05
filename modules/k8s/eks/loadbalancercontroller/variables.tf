variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_name_short" {
  description = "short name of cluster"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the cluster is located"
  type        = string
}

variable "replicas" {
  description = "num of replicas"
  type        = string
}

variable "karpenter_cluster" {
  description = "if this cluster uses Karpenter for node provisioning"
  type        = bool
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
}
