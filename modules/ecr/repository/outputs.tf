output "name" {
  value = aws_ecr_repository.main.name
}

output "arn" {
  value = aws_ecr_repository.main.arn
}

output "repository_url" {
  description = "<account>.dkr.ecr.<region>.amazonaws.com/<name>"
  value       = aws_ecr_repository.main.repository_url
}
