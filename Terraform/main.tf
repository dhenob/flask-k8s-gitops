provider "kubernetes" {
  config_path = var.kube_config_path
  config_context = "docker-desktop"
}

provider "helm" {
  kubernetes {
    config_path = var.kube_config_path
    config_context = "docker-desktop"
  }
}

variable "kube_config_path" {
  description = "Path to the kube config file"
  default     = "./kubeconfig"
}

variable "argocd_version" {
  description = "Version of Argo CD to deploy"
  default     = "3.26.8"
}

variable "argocd_domain" {
  description = "Domain name for Argo CD"
  default     = "argocd.local" 
}

# Namespace for Argo CD
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

# Namespace for Ingress Controller
resource "kubernetes_namespace" "ingress" {
  metadata {
    name = "nginx-ingress"
  }
}

# NGINX Ingress Controller
resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = kubernetes_namespace.ingress.metadata[0].name
  replace    = true  # Forces replacement of the conflicting resources
  force_update = true  # Update the release even if no changes are detected
  recreate_pods = true 

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"  
  }


}

# Argo CD
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name
}

# Argo CD Ingress
resource "kubernetes_ingress_v1" "argocd_ingress" {
  metadata {
    name      = "argocd-server-ingress"
    namespace = "argocd"
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
      # "nginx.ingress.kubernetes.io/ssl-redirect" = "false"
      "nginx.ingress.kubernetes.io/force-ssl-redirect": "false"
    }
  }

  spec {
    ingress_class_name = "nginx"
    rule {
        host = var.argocd_domain
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "argocd-server"
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
