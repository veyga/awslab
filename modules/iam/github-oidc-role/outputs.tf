output "role_arn" {
  description = "role-to-assume for aws-actions/configure-aws-credentials"
  value       = aws_iam_role.main.arn
}
