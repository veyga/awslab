# No SSO yet, so Kargo keeps its admin account. Its password and token signing key live
# in a Secret managed here instead of in the helm values (api.secret.name).
# Log in as `admin`; the password is the admin_password output.
resource "random_password" "admin" {
  length  = 32
  special = false
}

resource "random_password" "token_signing_key" {
  length  = 48
  special = false
}

resource "kubernetes_secret_v1" "admin" {
  metadata {
    name      = "kargo-admin-creds"
    namespace = var.namespace
  }

  data = {
    ADMIN_ACCOUNT_PASSWORD_HASH     = bcrypt(random_password.admin.result)
    ADMIN_ACCOUNT_TOKEN_SIGNING_KEY = random_password.token_signing_key.result
  }

  lifecycle {
    # bcrypt salts every call, so the hash would differ on every plan; it's only
    # recomputed when a password is regenerated
    ignore_changes       = [data]
    replace_triggered_by = [random_password.admin, random_password.token_signing_key]
  }
}

# Shared git credentials: a Secret labeled cred-type=git in the shared resources namespace
# (global.sharedResources, here Kargo's own namespace) is used by every Project. The regex
# covers every repo in the org: app repos (read, for freight and rendering) and the gitops
# repo (read/write, where promotions commit)
resource "kubernetes_secret_v1" "git" {
  metadata {
    name      = "repo-github-org"
    namespace = var.namespace
    labels = {
      "kargo.akuity.io/cred-type" = "git"
    }
  }

  data = {
    repoURL        = var.git.repo_url_regex
    repoURLIsRegex = "true"
    username       = "git" # any non-empty value works with a GitHub token
    password       = var.git.token
  }
}

# ECR read access for the Kargo controller (Warehouse image tags, `helm template` pulling
# chart dependencies). Kargo first tries a per-Project role, kargo-project-<project>, and
# falls back to this one when none exists: fine with a single tenant.
# https://docs.kargo.io/operator-guide/security/ambient-credentials
module "controller_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.10"

  name = "${var.cluster_name}-kargo-controller"
  additional_policy_arns = {
    ecr = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  }

  associations = {
    controller = {
      cluster_name    = var.cluster_name
      namespace       = var.namespace
      service_account = "kargo-controller" # created by the chart
    }
  }

  tags = var.tags
}

resource "helm_release" "kargo" {
  name       = "kargo"
  chart      = "kargo"
  repository = "oci://ghcr.io/akuity/kargo-charts"
  version    = var.chart_version

  namespace        = var.namespace
  create_namespace = false
  timeout          = 600

  values = [templatefile("${path.module}/values.tpl.yaml", {
    namespace                = var.namespace
    domain                   = var.domain
    ingress_class            = var.ingress.class
    cert_issuer              = var.ingress.cert_issuer
    admin_secret             = kubernetes_secret_v1.admin.metadata[0].name
    argocd_namespace         = var.argocd.namespace
    argocd_url               = var.argocd.url
    node_selector            = var.node_selector
    api_replicas             = var.api.replicas
    webhooks_server_replicas = var.webhooks_server.replicas
    # pod identity only reaches pods started after the association exists: changing
    # this annotation rolls the controller onto it
    controller_role_arn = module.controller_pod_identity.iam_role_arn
  })]

  depends_on = [module.controller_pod_identity]
}
