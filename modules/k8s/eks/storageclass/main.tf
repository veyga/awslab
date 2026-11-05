# volume binding mode
# - EBS volumes: Use WaitForFirstConsumer (zone-specific)
# - EFS volumes: Use Immediate (multi-AZ by design)
# - Multi-AZ clusters: Always use WaitForFirstConsumer for EBS

resource "kubernetes_storage_class" "gp3" {
  count = var.ebs ? 1 : 0
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner = "ebs.csi.aws.com"

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
