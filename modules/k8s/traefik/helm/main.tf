resource "helm_release" "ingress_traefik" {
  name       = "traefik"
  chart      = "traefik"
  repository = "https://traefik.github.io/charts"
  version    = "37.4.0"

  namespace        = var.namespace
  create_namespace = var.create_namespace

  values = [yamlencode(merge({
    image = var.image_override != null ? var.image_override : {
      registry   = "docker.io"
      repository = "traefik"
      tag        = var.traefik_version
    }

    deployment = merge(
      { kind = var.deployment.kind },
      var.deployment.kind != "DaemonSet" ? { replicas = var.deployment.replicas } : {}
    )

    updateStrategy = var.deployment.kind == "DaemonSet" ? {
      type = "RollingUpdate"
      rollingUpdate = {
        maxUnavailable = 1
        maxSurge       = 0
      }
    } : null

    affinity = var.deployment.kind != "DaemonSet" ? {
      podAntiAffinity = {
        requiredDuringSchedulingIgnoredDuringExecution = [{
          labelSelector = {
            matchLabels = {
              "app.kubernetes.io/name" = "traefik"
            }
          }
          topologyKey = "kubernetes.io/hostname"
        }]
      }
    } : {}

    logs = {
      general = {
        format   = var.log_format
        level    = var.log_level
        filePath = var.persist_logs ? "/logs/general.log" : ""
      }
      access = {
        enabled  = var.access_logs
        format   = var.access_logs_format
        filePath = var.persist_logs ? "/logs/access.log" : ""
      }
    }

    service = var.service_override != null ? var.service_override : {
      type = "LoadBalancer"
      annotations = {
        "service.beta.kubernetes.io/aws-load-balancer-type"            = "external"
        "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
        "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"
      }
      externalTrafficPolicy = "Local"
      internalTrafficPolicy = "Cluster"
    }

    metrics = {
      prometheus = {
        service = {
          enabled = true
        }
        serviceMonitor = {
          enabled = false # manage it separately in promstack
        }
      }
    }

    ingressClass = {
      enabled        = true
      isDefaultClass = true
    }
    },
    var.ports_override != null ? { ports = var.ports_override } : {},
    !var.persist_logs ? {} : {
      persistence = {
        enabled       = var.persist_logs
        name          = "traefik-logs"
        existingClaim = "traefik-logs-pvc"
        path          = "/logs"
      }
    },
  ))]
}
