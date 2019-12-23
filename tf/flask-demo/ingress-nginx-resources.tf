resource "kubernetes_service" "ingress_nginx_svc" {
  metadata {
    name      = "ingress-nginx"
    namespace = "ingress-nginx"
    labels = {
      "app.kubernetes.io/name"    = "ingress-nginx"
      "app.kubernetes.io/part-of" = "ingress-nginx"
    }
  }
  spec {
    selector = {
      "app.kubernetes.io/name"    = "ingress-nginx"
      "app.kubernetes.io/part-of" = "ingress-nginx"
    }
    port {
      name        = "http"
      port        = 80
      target_port = 80
      node_port   = 30000
      protocol    = "TCP"
    }
    port {
      name        = "https"
      port        = 443
      target_port = 443
      node_port   = 31000
      protocol    = "TCP"
    }

    type = "NodePort"
  }
}

resource "kubernetes_ingress" "flask_demo_ingress_nginx" {
  metadata {
    name      = "ingress-${var.project_name}"
    namespace = kubernetes_namespace.flask_demo_ns.id

    annotations = {
      "kubernetes.io/ingress.class"                       = "nginx"
      "nginx.ingress.kubernetes.io/proxy-connect-timeout" = "10"
      "nginx.ingress.kubernetes.io/proxy-send-timeout"    = "120"
      "nginx.ingress.kubernetes.io/proxy-read-timeout"    = "120"
      "nginx.ingress.kubernetes.io/lua-resty-waf"         = "active"
      "nginx.ingress.kubernetes.io/app-root"              = "/echo"
      "nginx.ingress.kubernetes.io/enable-cors"           = "true"
      "nginx.ingress.kubernetes.io/cors-allow-methods"    = "GET"
      "nginx.ingress.kubernetes.io/server-snippet"        = <<-EOF
server_tokens "off";
EOF
      "nginx.ingress.kubernetes.io/configuration-snippet" = <<-EOF
more_set_headers "Powered-By: http_ninja";
EOF
    }
  }

  spec {
    rule {
      http {
        path {
          path = "/echo"
          backend {
            service_name = kubernetes_service.flask_demo_svc.metadata.0.name
            service_port = kubernetes_service.flask_demo_svc.spec.0.port.0.port
          }
        }
      }
    }
  }
}