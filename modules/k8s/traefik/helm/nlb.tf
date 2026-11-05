# The NLB is created by the aws-load-balancer-controller for the traefik Service,
# so look it up by the tags the controller puts on it (for route53 alias records)
data "aws_lb" "traefik" {
  count = var.cluster_name != null ? 1 : 0

  tags = {
    "elbv2.k8s.aws/cluster" = var.cluster_name
    "service.k8s.aws/stack" = "${var.namespace}/traefik"
  }

  depends_on = [helm_release.ingress_traefik]
}
