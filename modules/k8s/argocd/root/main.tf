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

# The one Application Terraform manages: it syncs root/ in the gitops repo, which
# defines the AppProject + ApplicationSet that generate every app's Applications
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
        repoURL        = var.repo_url
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
