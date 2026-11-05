resource "kubernetes_service_account_v1" "main" {
  metadata {
    name      = var.service_account
    namespace = var.namespace
  }
}

module "pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.10"

  name                   = var.name
  additional_policy_arns = var.policy_arns

  associations = {
    main = {
      cluster_name    = var.cluster_name
      namespace       = var.namespace
      service_account = kubernetes_service_account_v1.main.metadata[0].name
    }
  }

  tags = var.tags
}
