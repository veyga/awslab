output "iam_role_arn" {
  description = "ARN of the IAM role for AWS Load Balancer Controller"
  value       = module.aws_load_balancer_controller_pod_identity.iam_role_arn
}