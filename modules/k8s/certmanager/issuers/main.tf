resource "kubernetes_manifest" "clusterissuer_prod" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "clusterissuer-prod"
    }
    spec = {
      acme = {
        email  = "andrewstefanich@gmail.com"
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "clusterissuer-prod-key"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = var.ingressclass
              }
            }
          }
        ]
      }
    }
  }
}

resource "kubernetes_manifest" "clusterissuer_staging" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "clusterissuer-staging"
    }
    spec = {
      acme = {
        email  = "andrewstefanich@gmail.com"
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "clusterissuer-staging-key"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = var.ingressclass
              }
            }
          }
        ]
      }
    }
  }
}
