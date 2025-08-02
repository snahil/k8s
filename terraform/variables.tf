variable "namespace" {
  description = "Namespace for the web application"
  type        = string
  default     = "webapp"
}

variable "app_name" {
  description = "Name of the web application"
  type        = string
  default     = "webapp"
}

variable "app_image" {
  description = "Docker image for the web application"
  type        = string
  default     = "nginx:1.24-alpine"
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