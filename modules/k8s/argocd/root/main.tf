# Lets Argo CD (and the ApplicationSet controller) read the private gitops repo
resource "kubernetes_secret_v1" "gitops_repo" {
  metadata {
    name      = "repo-gitops"
    namespace = var.namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type     = "git"
    url      = var.repo_url
    username = "git" # any non-empty value works with a GitHub token
    password = var.repo_token
  }
}

# Credential template: any repo URL under the org prefix (e.g. app repos whose deploy/kargo
# chart an Application installs) uses this token, without registering each repo
resource "kubernetes_secret_v1" "github_org_creds" {
  metadata {
    name      = "creds-github-org"
    namespace = var.namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repo-creds"
    }
  }

  data = {
    type     = "git"
    url      = var.org_url
    username = "git"
    password = var.repo_token
  }
}

# The one Application Terraform manages: the app-of-apps, syncing root_path in
# root_repo_url (awslab's argocd/root/: the AppProject + one Application per app). The gitops
# repo itself only holds what Kargo renders
resource "kubernetes_manifest" "root" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "root"
      namespace = var.namespace
      # deliberately no resources-finalizer: deleting root must not cascade-delete every
      # child app (an empty `finalizers = []` makes kubernetes_manifest report drift)
    }
    spec = {
      project = "default"
      source = {
        repoURL        = coalesce(var.root_repo_url, var.repo_url)
        targetRevision = var.target_revision
        path           = var.root_path
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = var.namespace
      }
      syncPolicy = {
        automated = {
          prune    = false
          selfHeal = true
        }
      }
    }
  }

  depends_on = [kubernetes_secret_v1.gitops_repo]
}
