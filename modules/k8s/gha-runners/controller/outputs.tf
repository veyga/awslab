output "namespace" {
  value = helm_release.controller.namespace
}

output "service_account_name" {
  description = "controller service account, referenced by every scale set"
  value       = "${var.release_name}-gha-rs-controller"
}

output "chart_version" {
  value = helm_release.controller.version
}
