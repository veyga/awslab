# actions-runner-controller (ARC): the operator + CRDs, installed once per cluster.
# Each scale set (see ../scale-set) registers with this controller.
resource "helm_release" "controller" {
  name       = var.release_name
  chart      = "gha-runner-scale-set-controller"
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  version    = var.chart_version

  namespace        = var.namespace
  create_namespace = false

  values = [yamlencode({
    replicaCount = var.replicas

    flags = {
      logLevel = var.log_level
    }

    nodeSelector = var.node_selector
    tolerations  = var.tolerations

    resources = {
      requests = {
        cpu    = "50m"
        memory = "128Mi"
      }
      limits = {
        memory = "256Mi"
      }
    }
  })]
}
