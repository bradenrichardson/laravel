variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "laravel-app"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.app_name))
    error_message = "The app_name must consist of alphanumerics, hyphens, and underscores only."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.environment))
    error_message = "The environment must consist of alphanumerics, hyphens, and underscores only."
  }
}