# Network Module - VPC/VNet
# Provider-agnostic interface for network infrastructure

variable "name" {
  description = "Name of the network"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC/VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway (cost savings for non-prod)"
  type        = bool
  default     = false
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
# AWS Implementation
# ============================================================================
# Uncomment this section when using AWS

# module "vpc" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "~> 5.0"
#
#   name = "${var.name}-vpc"
#   cidr = var.cidr_block
#
#   azs             = var.availability_zones
#   private_subnets = var.private_subnets
#   public_subnets  = var.public_subnets
#
#   enable_nat_gateway = var.enable_nat_gateway
#   single_nat_gateway = var.single_nat_gateway
#
#   enable_dns_hostnames = true
#   enable_dns_support   = true
#
#   # Tags required for EKS
#   public_subnet_tags = {
#     "kubernetes.io/role/elb" = 1
#   }
#
#   private_subnet_tags = {
#     "kubernetes.io/role/internal-elb" = 1
#   }
#
#   tags = local.common_tags
# }
#
# output "vpc_id" {
#   value = module.vpc.vpc_id
# }
#
# output "private_subnet_ids" {
#   value = module.vpc.private_subnets
# }
#
# output "public_subnet_ids" {
#   value = module.vpc.public_subnets
# }

# ============================================================================
# Azure Implementation
# ============================================================================
# Uncomment this section when using Azure

# resource "azurerm_virtual_network" "main" {
#   name                = "${var.name}-vnet"
#   address_space       = [var.cidr_block]
#   location            = var.location
#   resource_group_name = var.resource_group_name
#
#   tags = local.common_tags
# }
#
# resource "azurerm_subnet" "private" {
#   count                = length(var.private_subnets)
#   name                 = "${var.name}-private-${count.index + 1}"
#   resource_group_name  = var.resource_group_name
#   virtual_network_name = azurerm_virtual_network.main.name
#   address_prefixes     = [var.private_subnets[count.index]]
# }
#
# resource "azurerm_subnet" "public" {
#   count                = length(var.public_subnets)
#   name                 = "${var.name}-public-${count.index + 1}"
#   resource_group_name  = var.resource_group_name
#   virtual_network_name = azurerm_virtual_network.main.name
#   address_prefixes     = [var.public_subnets[count.index]]
# }
#
# output "vnet_id" {
#   value = azurerm_virtual_network.main.id
# }
#
# output "private_subnet_ids" {
#   value = azurerm_subnet.private[*].id
# }
#
# output "public_subnet_ids" {
#   value = azurerm_subnet.public[*].id
# }

# Placeholder outputs (remove when implementing)
output "network_id" {
  description = "ID of the VPC/VNet"
  value       = "placeholder-implement-provider-specific"
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = []
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = []
}
