# ECR Repository
resource "aws_ecr_repository" "app" {
  name                 = "laravel-app"
  image_tag_mutability = "MUTABLE"  # Allow tag overwriting

  image_scanning_configuration {
    scan_on_push = true  # Enable security scanning
  }

  # Optional: Enable encryption
  encryption_configuration {
    encryption_type = "KMS"
  }

  # Optional: Tags
  tags = {
    Name        = "laravel-app"
    Environment = "production"
  }
}

# ECR Repository Policy to allow ECS to pull images
resource "aws_ecr_repository_policy" "app_policy" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowECSPull"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      },
      {
        Sid    = "AllowAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
      }
    ]
  })
}


# Outputs
output "repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "registry_id" {
  value = aws_ecr_repository.app.registry_id
}