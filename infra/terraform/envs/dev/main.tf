# Task Manager API - Development Environment
# Terraform configuration for dev infrastructure

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    # Uncomment the provider you're using:
    
    # AWS Provider
    # aws = {
    #   source  = "hashicorp/aws"
    #   version = "~> 5.0"
    # }
    
    # Azure Provider
    # azurerm = {
    #   source  = "hashicorp/azurerm"
    #   version = "~> 3.0"
    # }
  }

  # Remote state configuration (recommended)
  # Uncomment and configure for your backend:
  
  # AWS S3 Backend
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "task-manager/dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
  
  # Azure Storage Backend
  # backend "azurerm" {
  #   resource_group_name  = "terraform-state-rg"
  #   storage_account_name = "tfstateaccount"
  #   container_name       = "tfstate"
  #   key                  = "task-manager/dev/terraform.tfstate"
  # }
}

# ============================================================================
# Provider Configuration
# ============================================================================

# AWS Provider (uncomment if using AWS)
# provider "aws" {
#   region = var.aws_region
#
#   default_tags {
#     tags = {
#       Environment = "dev"
#       Project     = "task-manager"
#       ManagedBy   = "terraform"
#     }
#   }
# }

# Azure Provider (uncomment if using Azure)
# provider "azurerm" {
#   features {}
#   subscription_id = var.azure_subscription_id
# }

# ============================================================================
# Variables
# ============================================================================

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "task-manager"
}

# AWS Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# Azure Variables
variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = ""
}

variable "azure_location" {
  description = "Azure location"
  type        = string
  default     = "eastus"
}

# Database
variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

# ============================================================================
# Locals
# ============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# ============================================================================
# Modules
# ============================================================================

# Network Module
module "network" {
  source = "../../modules/network"

  name        = local.name_prefix
  environment = var.environment
  cidr_block  = "10.0.0.0/16"
  
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  
  # Single NAT for dev (cost savings)
  enable_nat_gateway = true
  single_nat_gateway = true
  
  tags = local.common_tags
}

# Kubernetes Cluster
module "kubernetes" {
  source = "../../modules/kubernetes"

  name        = local.name_prefix
  environment = var.environment
  
  kubernetes_version = "1.28"
  network_id         = module.network.network_id
  subnet_ids         = module.network.private_subnet_ids
  
  # Smaller nodes for dev
  node_groups = {
    default = {
      instance_type  = "t3.medium"  # or "Standard_D2s_v3" for Azure
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      disk_size      = 30
      labels = {
        environment = "dev"
      }
    }
  }
  
  enable_cluster_autoscaler = true
  
  tags = local.common_tags
}

# Database
module "database" {
  source = "../../modules/database"

  name        = local.name_prefix
  environment = var.environment
  
  engine_version    = "15"
  instance_class    = "db.t3.micro"  # or "GP_Standard_D2s_v3" for Azure
  allocated_storage = 20
  
  database_name   = "taskmanager"
  master_username = "postgres"
  master_password = var.db_password
  
  subnet_ids = module.network.private_subnet_ids
  
  # Dev settings
  multi_az            = false
  deletion_protection = false
  
  tags = local.common_tags
}

# Container Registry
module "registry" {
  source = "../../modules/registry"

  name        = var.project_name
  environment = var.environment
  
  scan_on_push          = true
  lifecycle_policy_days = 14  # Shorter retention for dev
  
  tags = local.common_tags
}

# ============================================================================
# Outputs
# ============================================================================

output "kubernetes_cluster_endpoint" {
  description = "Kubernetes cluster endpoint"
  value       = module.kubernetes.cluster_endpoint
}

output "kubernetes_cluster_name" {
  description = "Kubernetes cluster name"
  value       = module.kubernetes.cluster_name
}

output "database_endpoint" {
  description = "Database endpoint"
  value       = module.database.endpoint
}

output "registry_url" {
  description = "Container registry URL"
  value       = module.registry.repository_url
}
