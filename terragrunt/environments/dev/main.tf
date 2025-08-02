# Create namespace
resource "kubernetes_namespace" "webapp" {
  metadata {
    name = "webapp"
    labels = {
      name      = "webapp"
      purpose   = "web-application"
      environment = var.environment
    }
  }
}

# Create webapp deployment
resource "kubernetes_deployment" "webapp" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.webapp.metadata[0].name
    labels = {
      app         = var.app_name
      version     = "v1"
      environment = var.environment
    }
  }

  spec {
    replicas = var.replicas

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = 1
        max_unavailable = 0
      }
    }

    selector {
      match_labels = {
        app = var.app_name
      }
    }

    template {
      metadata {
        labels = {
          app         = var.app_name
          version     = "v1"
          environment = var.environment
        }
      }

      spec {
        affinity {
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 100
              pod_affinity_term {
                label_selector {
                  match_expressions {
                    key      = "app"
                    operator = "In"
                    values   = [var.app_name]
                  }
                }
                topology_key = "kubernetes.io/hostname"
              }
            }
          }
        }

        container {
          image = var.app_image
          name  = var.app_name

          args = [
            "-listen=:8080",
            "-text=Hello World from Kubernetes! Pod: $HOSTNAME"
          ]

          port {
            container_port = 8080
          }

          resources {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          env {
            name = "HOSTNAME"
            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }
        }
      }
    }
  }
}

# Create webapp service
resource "kubernetes_service" "webapp" {
  metadata {
    name      = "${var.app_name}-service"
    namespace = kubernetes_namespace.webapp.metadata[0].name
    labels = {
      app         = var.app_name
      environment = var.environment
    }
  }

  spec {
    type = "ClusterIP"
    port {
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
      name        = "http"
    }
    selector = {
      app = var.app_name
    }
  }
}

# Create ingress
resource "kubernetes_ingress_v1" "webapp" {
  metadata {
    name      = "${var.app_name}-ingress"
    namespace = kubernetes_namespace.webapp.metadata[0].name
    labels = {
      app         = var.app_name
      environment = var.environment
    }
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
      "nginx.ingress.kubernetes.io/ssl-redirect"   = "false"
      "nginx.ingress.kubernetes.io/use-regex"      = "true"
    }
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      host = var.ingress_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.webapp.metadata[0].name
              port {
                number = 8080
              }
            }
          }
        }
        path {
          path      = "/hello"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.webapp.metadata[0].name
              port {
                number = 8080
              }
            }
          }
        }
        path {
          path      = "/health"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.webapp.metadata[0].name
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }
}

# PostgreSQL resources (if enabled)
resource "kubernetes_persistent_volume_claim" "postgres" {
  count = var.postgres_enabled ? 1 : 0
  
  metadata {
    name      = "postgres-pvc"
    namespace = kubernetes_namespace.webapp.metadata[0].name
    labels = {
      app         = "postgres"
      environment = var.environment
    }
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.postgres_storage
      }
    }
    storage_class_name = "standard"
  }
}

resource "kubernetes_stateful_set" "postgres" {
  count = var.postgres_enabled ? 1 : 0
  
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.webapp.metadata[0].name
    labels = {
      app         = "postgres"
      environment = var.environment
    }
  }

  spec {
    service_name = "postgres-service"
    replicas     = 1
    selector {
      match_labels = {
        app = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          app         = "postgres"
          environment = var.environment
        }
      }

      spec {
        container {
          name  = "postgres"
          image = var.postgres_image

          port {
            container_port = 5432
            name          = "postgres"
          }

          env {
            name  = "POSTGRES_DB"
            value = var.postgres_db
          }

          env {
            name  = "POSTGRES_USER"
            value = var.postgres_user
          }

          env {
            name  = "POSTGRES_PASSWORD"
            value = var.postgres_password
          }

          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }

          resources {
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          volume_mount {
            name       = "postgres-storage"
            mount_path = "/var/lib/postgresql/data"
          }

          liveness_probe {
            exec {
              command = ["pg_isready", "-U", var.postgres_user]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            exec {
              command = ["pg_isready", "-U", var.postgres_user]
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }

        volume {
          name = "postgres-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgres[0].metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "postgres" {
  count = var.postgres_enabled ? 1 : 0
  
  metadata {
    name      = "postgres-service"
    namespace = kubernetes_namespace.webapp.metadata[0].name
    labels = {
      app         = "postgres"
      environment = var.environment
    }
  }

  spec {
    type = "ClusterIP"
    port {
      port        = 5432
      target_port = 5432
      protocol    = "TCP"
      name        = "postgres"
    }
    selector = {
      app = "postgres"
    }
  }
} 