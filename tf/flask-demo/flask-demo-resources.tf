provider "kubernetes" {
  config_path = var.kube_config_path
}

resource "kubernetes_namespace" "flask_demo_ns" {
  metadata {
    name = var.project_name
  }
}

resource "kubernetes_daemonset" "flask_demo_ds" {
  metadata {
    name      = var.project_name
    namespace = kubernetes_namespace.flask_demo_ns.id
    labels = {
      app = var.project_name
    }
  }

  spec {
    selector {
      match_labels = {
        app = var.project_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.project_name
        }
      }

      spec {
        host_network = true
        container {
          image = var.docker_image
          name  = var.project_name
          port {
            container_port = 8000
            host_port      = 8000
          }

          resources {
            limits {
              cpu    = "0.5"
              memory = "512Mi"
            }

            requests {
              cpu    = "250m"
              memory = "50Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/status"
              port = 8000
            }

            initial_delay_seconds = 3
            period_seconds        = 30
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "flask_demo_svc" {
  metadata {
    name      = "${var.project_name}-service"
    namespace = kubernetes_namespace.flask_demo_ns.id
  }
  spec {
    selector = {
      app = kubernetes_daemonset.flask_demo_ds.metadata.0.labels.app
    }
    port {
      port        = 8000
      target_port = 8000
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}