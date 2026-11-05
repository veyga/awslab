variable "node_class_name" {
  description = "name for the nodeclass"
  type        = string
}

variable "cluster_name" {
  description = "name of cluster, for karpenter discovery"
  type        = string
}

variable "security_group_id" {
  description = "security group to use for karpenter provisioned nodes"
  type        = string
}

variable "subnets" {
  description = "list of subnets with id and zone to use for node provisioning"
  type = list(object({
    id = string
  }))
}

variable "tags" {
  description = "tags for provisioned nodes"
  type        = map(string)
  default     = {}
}

variable "ami" {
  description = "AMI type to use for nodes"
  type        = string

  validation {
    condition     = contains(["al2023", "bottlerocket"], var.ami)
    error_message = "AMI must be either 'al2023' or 'bottlerocket'."
  }
}

variable "root_volume_gb" {
  description = "Size of the root EBS volume in GB"
  type        = number

  validation {
    condition = (
      (var.ami == "al2023" && var.root_volume_gb >= 20) ||
      (var.ami == "bottlerocket" && var.root_volume_gb >= 8)
    )
    error_message = "Root volume size must be at least 20GB for AL2023 or at least 8GB for Bottlerocket."
  }
}
