output "service_account_name" {
  value = kubernetes_service_account_v1.main.metadata[0].name
}

output "role_arn" {
  value = module.pod_identity.iam_role_arn
}
