resource "aws_ecr_repository" "main" {
  name = var.name

  # tags are never overwritten, except the ones in mutable_tags (e.g. latest)
  image_tag_mutability = length(var.mutable_tags) > 0 ? "IMMUTABLE_WITH_EXCLUSION" : "IMMUTABLE"

  dynamic "image_tag_mutability_exclusion_filter" {
    for_each = var.mutable_tags
    content {
      filter      = image_tag_mutability_exclusion_filter.value
      filter_type = "WILDCARD"
    }
  }
  force_delete = var.force_delete

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}

locals {
  # an image matched by a higher priority rule is never expired by a lower one, so the
  # mutable tags rule shields those tags (latest) from the count rule after it
  lifecycle_rules = concat(
    [{
      description = "drop untagged images (failed/partial pushes)"
      selection = {
        tagStatus   = "untagged"
        countType   = "sinceImagePushed"
        countUnit   = "days"
        countNumber = 1
      }
    }],
    length(var.mutable_tags) == 0 ? [] : [{
      description = "keep the current image of each mutable tag"
      selection = {
        tagStatus      = "tagged"
        tagPatternList = var.mutable_tags
        countType      = "imageCountMoreThan"
        countNumber    = length(var.mutable_tags)
      }
    }],
    var.keep_images == null ? [] : [{
      description = "keep the newest ${var.keep_images} images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.keep_images
      }
    }],
  )
}

resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [
      for i, rule in local.lifecycle_rules : merge(rule, {
        rulePriority = i + 1
        action       = { type = "expire" }
      })
    ]
  })
}
