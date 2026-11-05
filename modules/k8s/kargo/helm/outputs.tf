output "url" {
  value = "https://${var.domain}"
}

output "admin_password" {
  description = "password for Kargo's `admin` account"
  value       = random_password.admin.result
  sensitive   = true
}
