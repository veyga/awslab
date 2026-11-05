resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  chart            = "cert-manager"
  repository       = "https://charts.jetstack.io"
  version          = "v1.18.2"
  namespace        = var.namespace
  create_namespace = var.create_namespace

  values = [
    yamlencode({
      installCRDs = var.install_crds
      # need this or cert renewal could break as we use Prefix for many ingresses
      featureGates = "ACMEHTTP01IngressPathTypeExact=false"
    })
  ]
}
