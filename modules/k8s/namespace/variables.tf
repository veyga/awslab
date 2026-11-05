variable "namespace" {
  description = "name for this namespace"
  type        = string
}

variable "dockerhub_creds_secret_name" {
  description = <<EOT
  if non-empty, creates the DH creds secret
  EOT
  type        = string
  default     = ""
}

variable "ecr_creds_secret_name" {
  description = <<EOT
  if non-empty, creates the ECR creds secret
  EOT
  type        = string
  default     = ""
}
