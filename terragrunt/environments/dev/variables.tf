variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "app_name" {
  description = "Name of the web application"
  type        = string
  default     = "webapp"
}

variable "app_image" {
  description = "Docker image for the web application"
  type        = string
  default     = "hashicorp/http-echo:latest"
}

variable "replicas" {
  description = "Number of replicas for the deployment"
  type        = number
  default     = 3
}

variable "cpu_request" {
  description = "CPU request for the container"
  type        = string
  default     = "50m"
}

variable "memory_request" {
  description = "Memory request for the container"
  type        = string
  default     = "64Mi"
}

variable "cpu_limit" {
  description = "CPU limit for the container"
  type        = string
  default     = "100m"
}

variable "memory_limit" {
  description = "Memory limit for the container"
  type        = string
  default     = "128Mi"
}

variable "ingress_host" {
  description = "Host for the ingress"
  type        = string
  default     = "webapp.local"
}

variable "postgres_enabled" {
  description = "Whether to deploy PostgreSQL"
  type        = bool
  default     = true
}

variable "postgres_image" {
  description = "PostgreSQL Docker image"
  type        = string
  default     = "postgres:15-alpine"
}

variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
  default     = "webapp"
}

variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
  default     = "postgres"
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  default     = "postgres123"
}

variable "postgres_storage" {
  description = "PostgreSQL storage size"
  type        = string
  default     = "1Gi"
} 