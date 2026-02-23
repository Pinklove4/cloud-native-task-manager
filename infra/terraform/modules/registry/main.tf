# Registry Module - ECR/ACR
# Provider-agnostic interface for container registry

variable "name" {
  description = "Name of the container registry"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "image_tag_mutability" {
  description = "Image tag mutability (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true
}

variable "lifecycle_policy_days" {
  description = "Number of days to retain untagged images"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

# Common tags
locals {
  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = "task-manager"
    },
    var.tags
  )
}

# ============================================================================
# AWS ECR Implementation
# ============================================================================
# Uncomment this section when using AWS

# resource "aws_ecr_repository" "main" {
#   name                 = var.name
#   image_tag_mutability = var.image_tag_mutability
#
#   image_scanning_configuration {
#     scan_on_push = var.scan_on_push
#   }
#
#   encryption_configuration {
#     encryption_type = "AES256"
#   }
#
#   tags = local.common_tags
# }
#
# resource "aws_ecr_lifecycle_policy" "main" {
#   repository = aws_ecr_repository.main.name
#
#   policy = jsonencode({
#     rules = [
#       {
#         rulePriority = 1
#         description  = "Remove untagged images older than ${var.lifecycle_policy_days} days"
#         selection = {
#           tagStatus   = "untagged"
#           countType   = "sinceImagePushed"
#           countUnit   = "days"
#           countNumber = var.lifecycle_policy_days
#         }
#         action = {
#           type = "expire"
#         }
#       },
#       {
#         rulePriority = 2
#         description  = "Keep only last 50 images"
#         selection = {
#           tagStatus   = "any"
#           countType   = "imageCountMoreThan"
#           countNumber = 50
#         }
#         action = {
#           type = "expire"
#         }
#       }
#     ]
#   })
# }
#
# output "repository_url" {
#   value = aws_ecr_repository.main.repository_url
# }
#
# output "registry_id" {
#   value = aws_ecr_repository.main.registry_id
# }

# ============================================================================
# Azure ACR Implementation
# ============================================================================
# Uncomment this section when using Azure

# resource "azurerm_container_registry" "main" {
#   name                = replace("${var.name}${var.environment}", "-", "")
#   resource_group_name = var.resource_group_name
#   location            = var.location
#   sku                 = "Standard"
#   admin_enabled       = false
#
#   tags = local.common_tags
# }
#
# # Note: ACR image scanning requires Defender for Cloud
# # Lifecycle policies are configured via ACR Tasks
#
# output "repository_url" {
#   value = azurerm_container_registry.main.login_server
# }
#
# output "registry_id" {
#   value = azurerm_container_registry.main.id
# }

# Placeholder outputs (remove when implementing)
output "repository_url" {
  description = "Container registry URL"
  value       = "placeholder-implement-provider-specific"
}

output "registry_id" {
  description = "Container registry ID"
  value       = "placeholder-implement-provider-specific"
}
