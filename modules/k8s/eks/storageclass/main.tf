# volume binding mode
# - EBS volumes: Use WaitForFirstConsumer (zone-specific)
# - EFS volumes: Use Immediate (multi-AZ by design)
# - Multi-AZ clusters: Always use WaitForFirstConsumer for EBS

resource "kubernetes_storage_class" "gp3" {
  count = var.ebs ? 1 : 0
  metadata {
    name = var.eks_auto ? "gp3-eks-auto" : "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner = var.eks_auto ? "ebs.csi.eks.amazonaws.com" : "ebs.csi.aws.com"

  parameters = merge({
    type   = "gp3"
    fsType = "ext4"
    }, length(var.tags) > 0 ? merge({
      "tagSpecification_1_resourceType" = "volume"
      }, {
      for k, v in var.tags : "tagSpecification_1_tags_${k}" => v
  }) : {})

  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
}

resource "kubernetes_storage_class" "efs" {
  count = var.efs.id != null ? 1 : 0
  metadata {
    name = "efs"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "false"
    }
  }

  storage_provisioner = "efs.csi.aws.com"

  parameters = merge({
    provisioningMode = "efs-ap"
    fileSystemId     = var.efs.id
    directoryPerms   = "700"
    gidRangeStart    = "1000"
    gidRangeEnd      = "2000"
    }, {
    tags = join(",", [for k, v in var.tags : "${k}=${v}"])
  })

  reclaim_policy         = "Delete"
  volume_binding_mode    = "Immediate"
  allow_volume_expansion = true
}
