resource "helm_release" "argocd" {
  name       = "argocd"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  version    = var.chart_version

  namespace        = var.namespace
  create_namespace = var.create_namespace
  timeout          = 600

  values = [templatefile("${path.module}/values.tpl.yaml", {
    domain               = var.domain
    ingress_enabled      = var.ingress.enabled
    ingress_class        = var.ingress.class
    ingress_annotations  = var.ingress.annotations
    cert_issuer          = var.ingress.cert_issuer
    node_selector        = var.node_selector
    server_replicas      = var.server.replicas
    repo_server_replicas = var.repo_server.replicas
    controller_replicas  = var.controller.replicas
  })]
}
