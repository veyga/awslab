output "repository_uri" {
  description = "public.ecr.aws/<registry alias>/<name>"
  value       = aws_ecrpublic_repository.main.repository_uri
}
