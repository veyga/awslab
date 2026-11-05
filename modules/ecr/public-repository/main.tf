# ECR Public: anyone can pull, anonymously (no credentials for Argo CD, Kargo or helm).
# Pushing still needs IAM (ecr-public:* + sts:GetServiceBearerToken). us-east-1 only.
resource "aws_ecrpublic_repository" "main" {
  repository_name = var.name

  catalog_data {
    description = var.description
  }

  tags = var.tags
}
