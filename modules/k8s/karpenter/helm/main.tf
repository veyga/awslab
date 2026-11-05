resource "helm_release" "karpenter" {
  namespace  = "kube-system"
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart   = "karpenter"
  version = var.karpenter_version
  wait    = false

  values = [
    <<-EOT
    replicas: ${var.replicas}
    nodeSelector:
      karpenter.sh/controller: 'true'
    tolerations:
      - key: karpenter.sh/controller
        operator: Equal
        value: 'true'
        effect: NoSchedule
    dnsPolicy: Default
    settings:
      clusterName: ${var.cluster_name}
      clusterEndpoint: ${var.cluster_endpoint}
      interruptionQueue: ${var.karpenter_queue_name}
    webhook:
      enabled: false
    EOT
  ]
}
