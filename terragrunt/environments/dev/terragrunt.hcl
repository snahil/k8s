# Dev environment configuration
include "root" {
  path = find_in_parent_folders()
}

# Environment-specific variables
inputs = {
  environment = "dev"
  
  # Application configuration
  app_name    = "webapp"
  app_image   = "hashicorp/http-echo:latest"
  replicas    = 3
  
  # Resource limits
  cpu_request    = "50m"
  memory_request = "64Mi"
  cpu_limit      = "100m"
  memory_limit   = "128Mi"
  
  # Ingress configuration
  ingress_host = "webapp.local"
  
  # PostgreSQL configuration
  postgres_enabled = true
  postgres_image   = "postgres:15-alpine"
  postgres_db      = "webapp"
  postgres_user    = "postgres"
  postgres_password = "postgres123"
  postgres_storage = "1Gi"
} 