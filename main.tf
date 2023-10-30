# main.tf

provider "azurerm" {
  features {}
}

provider "kubernetes" {
  config_context = "your-kube-context"
}

# Use data block to fetch the AKS cluster credentials
data "azurerm_kubernetes_cluster" "existing_aks" {
  name                = "your-aks-cluster-name"
  resource_group_name = "your-aks-resource-group"
}

resource "kubernetes_namespace" "sonarqube" {
  metadata {
    name = "sonarqube-namespace"
  }
}

resource "kubernetes_deployment" "sonarqube" {
  metadata {
    name     = "sonarqube-deployment"
    namespace = kubernetes_namespace.sonarqube.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "sonarqube"
      }
    }

    template {
      metadata {
        labels = {
          app = "sonarqube"
        }
      }

      spec {
        container {
          name  = "sonarqube"
          image = "sonarqube:latest"

          env {
            name  = "SONARQUBE_JDBC_URL"
            value = "jdbc:mysql://mysql-server:3306/sonar"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "sonarqube" {
  metadata {
    name      = "sonarqube-service"
    namespace = kubernetes_namespace.sonarqube.metadata[0].name
  }

  spec {
    selector = {
      app = kubernetes_deployment.sonarqube.spec[0].template[0].metadata[0].labels.app
    }

    port {
      port        = 9000
      target_port = 9000
    }

    type = "LoadBalancer"
  }
}
