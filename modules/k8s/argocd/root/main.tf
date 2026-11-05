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

# The one Application Terraform manages: the app-of-apps. One source per app repo, each
# syncing that repo's deploy/application.yaml (an ApplicationSet: the app's per-stage
# Applications + its Kargo pipeline). The gitops repo only holds what Kargo renders.
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
      sources = [
        for repo in var.app_repos : {
          repoURL        = repo
          targetRevision = var.target_revision
          path           = "."
          directory = {
            recurse = true
            include = "deploy/application.yaml"
          }
        }
      ]
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
