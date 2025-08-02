output "namespace" {
  description = "The namespace created for the web application"
  value       = kubernetes_namespace.webapp.metadata[0].name
}

output "deployment_name" {
  description = "The name of the webapp deployment"
  value       = kubernetes_deployment.webapp.metadata[0].name
}

output "service_name" {
  description = "The name of the webapp service"
  value       = kubernetes_service.webapp.metadata[0].name
}

output "ingress_name" {
  description = "The name of the webapp ingress"
  value       = kubernetes_ingress_v1.webapp.metadata[0].name
}

output "application_url" {
  description = "The URL to access the application"
  value       = "http://${var.ingress_host}"
}

output "health_check_url" {
  description = "The URL for health checks"
  value       = "http://${var.ingress_host}/health"
}

output "hello_endpoint_url" {
  description = "The URL for the hello endpoint"
  value       = "http://${var.ingress_host}/hello"
}

output "postgres_enabled" {
  description = "Whether PostgreSQL is enabled"
  value       = var.postgres_enabled
}

output "postgres_service_name" {
  description = "The name of the PostgreSQL service"
  value       = var.postgres_enabled ? kubernetes_service.postgres[0].metadata[0].name : null
}

output "environment" {
  description = "The environment name"
  value       = var.environment
} 