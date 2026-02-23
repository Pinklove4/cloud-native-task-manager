# Database Module - RDS/Azure Database for PostgreSQL
# Provider-agnostic interface for managed PostgreSQL

variable "name" {
  description = "Name of the database instance"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "engine_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15"
}

variable "instance_class" {
  description = "Instance class/SKU"
  type        = string
  default     = "db.t3.medium"  # AWS
  # default   = "GP_Standard_D2s_v3"  # Azure
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum storage for autoscaling (GB)"
  type        = number
  default     = 100
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "taskmanager"
}

variable "master_username" {
  description = "Master username"
  type        = string
  default     = "postgres"
}

variable "master_password" {
  description = "Master password"
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  description = "Subnet IDs for the database"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "Security group IDs"
  type        = list(string)
  default     = []
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
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
# AWS RDS Implementation
# ============================================================================
# Uncomment this section when using AWS

# resource "aws_db_subnet_group" "main" {
#   name       = "${var.name}-subnet-group"
#   subnet_ids = var.subnet_ids
#
#   tags = local.common_tags
# }
#
# resource "aws_db_instance" "main" {
#   identifier = "${var.name}-postgres"
#
#   engine               = "postgres"
#   engine_version       = var.engine_version
#   instance_class       = var.instance_class
#   allocated_storage    = var.allocated_storage
#   max_allocated_storage = var.max_allocated_storage
#
#   db_name  = var.database_name
#   username = var.master_username
#   password = var.master_password
#
#   db_subnet_group_name   = aws_db_subnet_group.main.name
#   vpc_security_group_ids = var.vpc_security_group_ids
#
#   multi_az               = var.multi_az
#   publicly_accessible    = false
#   deletion_protection    = var.deletion_protection
#   skip_final_snapshot    = var.environment != "prod"
#   backup_retention_period = var.backup_retention_period
#
#   storage_encrypted = true
#
#   # Performance Insights
#   performance_insights_enabled = var.environment == "prod"
#
#   tags = local.common_tags
# }
#
# output "endpoint" {
#   value = aws_db_instance.main.endpoint
# }
#
# output "database_name" {
#   value = aws_db_instance.main.db_name
# }
#
# output "connection_string" {
#   value     = "postgresql://${var.master_username}:${var.master_password}@${aws_db_instance.main.endpoint}/${var.database_name}"
#   sensitive = true
# }

# ============================================================================
# Azure Database for PostgreSQL Implementation
# ============================================================================
# Uncomment this section when using Azure

# resource "azurerm_postgresql_flexible_server" "main" {
#   name                   = "${var.name}-postgres"
#   resource_group_name    = var.resource_group_name
#   location               = var.location
#   version                = var.engine_version
#   delegated_subnet_id    = var.subnet_ids[0]
#   administrator_login    = var.master_username
#   administrator_password = var.master_password
#   zone                   = "1"
#
#   storage_mb = var.allocated_storage * 1024
#
#   sku_name = var.instance_class
#
#   backup_retention_days = var.backup_retention_period
#
#   tags = local.common_tags
# }
#
# resource "azurerm_postgresql_flexible_server_database" "main" {
#   name      = var.database_name
#   server_id = azurerm_postgresql_flexible_server.main.id
#   charset   = "UTF8"
#   collation = "en_US.utf8"
# }
#
# output "endpoint" {
#   value = azurerm_postgresql_flexible_server.main.fqdn
# }
#
# output "database_name" {
#   value = azurerm_postgresql_flexible_server_database.main.name
# }
#
# output "connection_string" {
#   value     = "postgresql://${var.master_username}:${var.master_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${var.database_name}"
#   sensitive = true
# }

# Placeholder outputs (remove when implementing)
output "endpoint" {
  description = "Database endpoint"
  value       = "placeholder-implement-provider-specific"
}

output "database_name" {
  description = "Database name"
  value       = var.database_name
}
