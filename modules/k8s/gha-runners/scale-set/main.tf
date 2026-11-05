locals {
  secret_name = "${var.name}-github"
  use_app     = var.github_app != null
}

# Credentials ARC uses to register runners with GitHub: either a GitHub App or a PAT
resource "kubernetes_secret_v1" "github" {
  metadata {
    name      = local.secret_name
    namespace = var.namespace
  }

  data = local.use_app ? {
    github_app_id              = var.github_app.app_id
    github_app_installation_id = var.github_app.installation_id
    github_app_private_key     = var.github_app.private_key
    } : {
    github_token = var.github_token
  }

  lifecycle {
    precondition {
      condition     = local.use_app || var.github_token != ""
      error_message = "set either github_app or github_token"
    }
  }
}

# A runner scale set: a listener (long-polls GitHub) plus one ephemeral runner pod per job.
# Workflows target it with `runs-on: <name>`.
resource "helm_release" "scale_set" {
  name       = var.name
  chart      = "gha-runner-scale-set"
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  version    = var.chart_version

  namespace        = var.namespace
  create_namespace = false

  values = [yamlencode(merge(var.container_mode == null ? {} : {
    # dind: a privileged docker daemon sidecar, so jobs can use `container:`, services
    # and docker build
    containerMode = { type = var.container_mode }
    }, {
    githubConfigUrl    = var.github_config_url
    githubConfigSecret = kubernetes_secret_v1.github.metadata[0].name

    runnerScaleSetName = var.name
    minRunners         = var.min_runners
    maxRunners         = var.max_runners

    controllerServiceAccount = {
      namespace = var.controller.namespace
      name      = var.controller.service_account_name
    }

    # listener: one small always-on pod per scale set
    listenerTemplate = {
      spec = {
        nodeSelector = var.listener_node_selector
        tolerations  = var.listener_tolerations
        containers = [{
          name = "listener"
          resources = {
            requests = { cpu = "50m", memory = "128Mi" }
            limits   = { memory = "128Mi" }
          }
        }]
      }
    }

    # runner: one ephemeral pod per job
    template = {
      spec = {
        serviceAccountName = var.runner_service_account
        nodeSelector       = var.runner_node_selector
        tolerations        = var.runner_tolerations
        containers = [{
          name    = "runner"
          image   = var.runner_image
          command = ["/home/runner/run.sh"]
          resources = {
            requests = {
              cpu    = var.runner_resources.cpu
              memory = var.runner_resources.memory
            }
            limits = {
              memory = var.runner_resources.memory_limit
            }
          }
        }]
      }
    }
  }))]
}
