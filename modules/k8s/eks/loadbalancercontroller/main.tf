locals {
  id_name = var.cluster_name_short != "" ? var.cluster_name_short : var.cluster_name
}

module "aws_load_balancer_controller_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"
  name   = "${local.id_name}-aws-load-balancer-controller"

  attach_aws_lb_controller_policy = true

  associations = {
    ex-one = {
      cluster_name    = var.cluster_name
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
    }
  }

  tags = var.tags
}

# need this to provision network load balancers
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.13.4"
  namespace  = "kube-system"

  values = [yamlencode({
    clusterName = var.cluster_name
    region      = var.aws_region
    vpcId       = var.vpc_id

    replicaCount = var.replicas

    serviceAccount = {
      create = true
      name   = "aws-load-balancer-controller"
    }

    nodeSelector = var.karpenter_cluster ? {
      "karpenter.sh/controller" = "true"
    } : null

    tolerations = var.karpenter_cluster ? [{
      key      = "karpenter.sh/controller"
      operator = "Equal"
      value    = "true"
      effect   = "NoSchedule"
    }] : null

    defaultTags = var.tags
  })]

  depends_on = [module.aws_load_balancer_controller_pod_identity]
}

