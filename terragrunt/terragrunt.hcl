# Root terragrunt.hcl file
# This file contains common configuration for all environments

locals {
  # Parse the terragrunt.hcl file to extract the path
  path_relative_to_include = path_relative_to_include()
  
  # Parse the path to extract environment and component
  path_parts = split("/", local.path_relative_to_include)
  environment = local.path_parts[0]
  component   = local.path_parts[1]
}

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}
EOF
}

# Configure Terragrunt to automatically store tfstate files in S3
remote_state {
  backend = "local"
  
  config = {
    path = "${get_parent_terragrunt_dir()}/.terragrunt-cache/${path_relative_to_include()}/terraform.tfstate"
  }
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Configure input variables
inputs = {
  environment = local.environment
  component   = local.component
  
  # Common tags
  common_tags = {
    Environment = local.environment
    Component   = local.component
    ManagedBy   = "Terragrunt"
  }
} 