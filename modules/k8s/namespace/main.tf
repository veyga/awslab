resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace

    labels = {
      client     = "ops"
      created_by = "terraform"
    }
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations["cattle.io/status"],
      metadata[0].annotations["lifecycle.cattle.io/create.namespace-auth"],
      metadata[0].annotations["field.cattle.io/projectId"],
      metadata[0].annotations["management.cattle.io/no-default-sa-token"],
      metadata[0].labels["field.cattle.io/projectId"],
    ]
  }
}

resource "kubernetes_manifest" "dockerhub_creds" {
  count = var.dockerhub_creds_secret_name == "" ? 0 : 1
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = var.dockerhub_creds_secret_name
      namespace = var.namespace
    }
    spec = {
      refreshInterval = "72h"
      secretStoreRef = {
        name = "kv-ops"
        kind = "ClusterSecretStore"
      }
      target = {
        name           = var.dockerhub_creds_secret_name
        creationPolicy = "Owner"
        template = {
          type = "kubernetes.io/dockerconfigjson"
          data = {
            ".dockerconfigjson" = "{{ .credsjson }}"
          }
        }
      }
      data = [
        {
          secretKey = "credsjson"
          remoteRef = {
            key      = "registries/dockerhub"
            property = ".dockerconfigjson"
          }
        }
      ]
    }
  }

  depends_on = [kubernetes_namespace.this]
}

resource "kubernetes_manifest" "ecr_creds" {
  count = var.ecr_creds_secret_name == "" ? 0 : 1
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = var.ecr_creds_secret_name
      namespace = var.namespace
    }
    spec = {
      refreshInterval = "4h"
      secretStoreRef = {
        name = "kv-ops"
        kind = "ClusterSecretStore"
      }
      target = {
        name           = var.ecr_creds_secret_name
        creationPolicy = "Owner"
        template = {
          type = "kubernetes.io/dockerconfigjson"
          data = {
            ".dockerconfigjson" = "{{ .credsjson }}"
          }
        }
      }
      data = [
        {
          secretKey = "credsjson"
          remoteRef = {
            key      = "registries/ecr"
            property = ".dockerconfigjson"
          }
        }
      ]
    }
  }

  depends_on = [kubernetes_namespace.this]
}
