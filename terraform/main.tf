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

# Create namespace
resource "kubernetes_namespace" "webapp" {
  metadata {
    name = "webapp"
    labels = {
      name    = "webapp"
      purpose = "web-application"
    }
  }
}

# Create ConfigMap for nginx configuration
resource "kubernetes_config_map" "nginx_config" {
  metadata {
    name      = "nginx-config"
    namespace = kubernetes_namespace.webapp.metadata[0].name
  }

  data = {
    "default.conf" = <<-EOF
      server {
          listen 80;
          server_name webapp.local;
          
          location / {
              root /usr/share/nginx/html;
              index index.html index.htm;
              try_files $uri $uri/ /index.html;
          }
          
          location /health {
              access_log off;
              return 200 "healthy\n";
              add_header Content-Type text/plain;
          }
          
          location /app {
              return 200 "Hello from Kubernetes! Pod: $hostname\n";
              add_header Content-Type text/plain;
          }
      }
    EOF
  }
}

# Create webapp deployment
resource "kubernetes_deployment" "webapp" {
  metadata {
    name      = "webapp"
    namespace = kubernetes_namespace.webapp.metadata[0].name
    labels = {
      app     = "webapp"
      version = "v1"
    }
  }

  spec {
    replicas = 3

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = 1
        max_unavailable = 0
      }
    }

    selector {
      match_labels = {
        app = "webapp"
      }
    }

    template {
      metadata {
        labels = {
          app     = "webapp"
          version = "v1"
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
                    values   = ["webapp"]
                  }
                }
                topology_key = "kubernetes.io/hostname"
              }
            }
          }
        }

        container {
          image = "nginx:1.24-alpine"
          name  = "webapp"

          port {
            container_port = 80
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          env {
            name  = "NGINX_HOST"
            value = "webapp.local"
          }

          env {
            name  = "NGINX_PORT"
            value = "80"
          }

          volume_mount {
            name       = "nginx-config"
            mount_path = "/etc/nginx/conf.d"
          }
        }

        volume {
          name = "nginx-config"
          config_map {
            name = kubernetes_config_map.nginx_config.metadata[0].name
          }
        }
      }
    }
  }
}

# Create webapp service
resource "kubernetes_service" "webapp" {
  metadata {
    name      = "webapp-service"
    namespace = kubernetes_namespace.webapp.metadata[0].name
    labels = {
      app = "webapp"
    }
  }

  spec {
    type = "ClusterIP"
    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
      name        = "http"
    }
    selector = {
      app = "webapp"
    }
  }
}

# Create ingress
resource "kubernetes_ingress_v1" "webapp" {
  metadata {
    name      = "webapp-ingress"
    namespace = kubernetes_namespace.webapp.metadata[0].name
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
      "nginx.ingress.kubernetes.io/ssl-redirect"   = "false"
      "nginx.ingress.kubernetes.io/use-regex"      = "true"
    }
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      host = "webapp.local"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.webapp.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
        path {
          path      = "/app"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.webapp.metadata[0].name
              port {
                number = 80
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
                number = 80
              }
            }
          }
        }
      }
    }
  }
} 