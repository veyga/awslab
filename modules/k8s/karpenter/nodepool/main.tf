locals {
  group = "karpenter.k8s.aws"
}

resource "kubernetes_manifest" "karpenter_nodepool" {
  # field_manager {
  #   force_conflicts = true
  # }

  lifecycle {
    ignore_changes = [
      object.spec.weight
    ]
  }

  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = var.name
    }
    spec = {
      disruption = {
        budgets = [
          {
            nodes = var.disruption_percentage
          }
        ]
        consolidationPolicy = "WhenEmptyOrUnderutilized"
        consolidateAfter    = var.consolidate_after
      }

      weight = var.weight

      template = {
        metadata = {
          labels = var.labels
        }
        spec = {
          expireAfter            = "336h"
          terminationGracePeriod = var.termination_grace_period
          nodeClassRef = {
            group = local.group
            kind  = "EC2NodeClass"
            name  = var.node_class
          }
          requirements = [
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = var.capacity_types
            },
            {
              key      = "${local.group}/instance-category"
              operator = "In"
              values   = var.instance_categories
            },
            {
              key      = "${local.group}/instance-size"
              operator = "In"
              values   = var.instance_sizes
            },
            {
              key      = "${local.group}/instance-generation"
              operator = "Gt"
              values   = ["${var.min_instance_generation}"]
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            },
            {
              key      = "kubernetes.io/os"
              operator = "In"
              values   = ["linux"]
            },
            # Prevent scheduling on nodes under resource pressure
            # This forces Karpenter to provision new nodes instead of overloading existing ones
            {
              key      = "node.kubernetes.io/memory-pressure"
              operator = "DoesNotExist"
              # DoesNotExist = only schedule on nodes that DON'T have memory pressure
              # Prevents page faults by avoiding memory-stressed nodes
            },
            {
              key      = "node.kubernetes.io/disk-pressure"
              operator = "DoesNotExist"
              # DoesNotExist = only schedule on nodes that DON'T have disk pressure
              # Prevents disk space issues from affecting scheduling
            }
          ]

          taints = [
            for taint in var.taints : {
              key    = taint.key
              value  = taint.value
              effect = taint.effect
            }
          ]
        }
      }
    }
  }
}
