variable "name" {
  description = "name of the node pool"
  type        = string
}

variable "disruption_percentage" {
  description = "how many nodes can be replaced at once"
  type        = string
}

variable "consolidate_after" {
  description = "how long to wait before removing node"
  type        = string
}

variable "node_class" {
  type        = string
  description = "node class name"
}

variable "capacity_types" {
  type = list(string)
}

variable "instance_categories" {
  type = list(string)
}

variable "min_instance_generation" {
  type = number
}

variable "instance_sizes" {
  type = list(string)
}

variable "termination_grace_period" {
  type        = string
  description = <<-EOT
    How long to wait for pods to gracefully shut down before terminating the node.
  EOT
}

variable "taints" {
  description = "list of taints to apply to nodes"
  type = list(object({
    key    = string
    value  = string
    effect = optional(string, "NoSchedule")
  }))
  default = []
}

variable "labels" {
  description = "labels to apply to nodes"
  type        = map(string)
  default     = {}
}

variable "weight" {
  description = "Priority weight for this nodepool (higher = preferred)"
  type        = number
  default     = null
}
