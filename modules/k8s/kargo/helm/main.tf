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
# (global.sharedResources, here Kargo's own namespace) is used by every Project for
# matching repo URLs, so promotions can commit to the gitops repo
resource "kubernetes_secret_v1" "gitops_repo" {
  metadata {
    name      = "repo-gitops"
    namespace = var.namespace
    labels = {
      "kargo.akuity.io/cred-type" = "git"
    }
  }

  data = {
    repoURL  = var.gitops_repo.url
    username = "git" # any non-empty value works with a GitHub token
    password = var.gitops_repo.token
  }
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
  })]
}
