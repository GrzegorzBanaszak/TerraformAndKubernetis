provider "docker" {}




locals {
  images_dir = "${path.root}/images"
  build_images = [
    docker_image.node_app.image_id
  ]
}

// Stworzenie kontenera dla aplikacji node
resource "docker_image" "node_app" {
  name = "node-app"
  build {
    context = "${local.images_dir}/node-app"
    tag     = ["node-app:test"]
  }
}


# //Uruchomiwenie kontenera
# resource "docker_container" "web_app" {
#   name  = "web_app"
#   image = docker_image.node_app.image_id
#   ports {
#     internal = 3000
#     external = 3000
#   }
# }



provider "minikube" {
  kubernetes_version = "v1.31.1"
}

resource "minikube_cluster" "docker" {
  driver       = "docker"
  cluster_name = "kubernetes"
  cni          = "bridge"
  addons = [
    "default-storageclass",
    "storage-provisioner",
    "ingress",
    "ingress-dns",
    "dashboard"
  ]
}


provider "kubernetes" {
  host = minikube_cluster.docker.host

  client_certificate     = minikube_cluster.docker.client_certificate
  client_key             = minikube_cluster.docker.client_key
  cluster_ca_certificate = minikube_cluster.docker.cluster_ca_certificate
}


resource "kubernetes_namespace_v1" "main_namespace" {
  metadata {
    name = "main-namespace"
    labels = {
      "origin" = "terraform"
    }
  }
}

resource "kubernetes_deployment_v1" "my-app-deployment" {
  metadata {
    name      = "${var.web_app_name}-deployment"
    namespace = kubernetes_namespace_v1.main_namespace.metadata[0].name
    labels = {
      "app" = var.web_app_name
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        "app" = var.web_app_name
      }
    }

    template {
      metadata {
        labels = {
          "app" = var.web_app_name
        }
      }
      spec {
        container {
          name  = "${var.web_app_name}-deployment"
          image = "node-app:test"


          port {
            container_port = var.port
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
        }
      }
    }
  }
}


resource "kubernetes_service_v1" "my-app-service" {
  metadata {
    name      = "${var.web_app_name}-service"
    namespace = kubernetes_namespace_v1.main_namespace.metadata[0].name
  }

  spec {
    selector = {
      "app" = var.web_app_name
    }

    port {
      port        = var.port
      target_port = var.port
    }
  }

  depends_on = [kubernetes_deployment_v1.my-app-deployment]
}


resource "kubernetes_ingress_v1" "web-server-ingress" {
  metadata {
    name      = "${var.web_app_name}-ingress"
    namespace = kubernetes_namespace_v1.main_namespace.metadata[0].name
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      host = "web-server.tf.npi-cluster"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.my-app-service.metadata[0].name
              port {
                name = "http"
              }
            }
          }
        }
      }
    }
  }
}

