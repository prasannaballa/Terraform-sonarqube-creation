# main.tf
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}
provider "azurerm" {
    features {
      
    }
    subscription_id = var.subscription_id
    client_id = var.client_id
    client_secret = var.client_secret
    tenant_id =var.tenant_id


}
terraform {
  backend "azurerm" {
    resource_group_name = "sivaaks"
    storage_account_name = "webacr"
    container_name = "sonarqube"
    key = "sonarqube"
    access_key = "SP7p/X+ZnFhAoufkEaBk+4cqKJdhIQpbrITUiQD5g1mWi2vLhbLxYdcMPafRIbULWBVrXdavUMjs+AStdYHRdg=="
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "sivaaks"
}

# Use data block to fetch the AKS cluster credentials
data "azurerm_kubernetes_cluster" "existing_aks" {
  name                = "sivaaks"
  resource_group_name = "sivaaks"
}

resource "kubernetes_namespace" "sonarqube" {
  metadata {
    name = "sonarqube-namespace"
  }
}

resource "kubernetes_deployment" "sonarqube" {
  metadata {
    name     = "sonarqube-deployment"
    namespace = kubernetes_namespace.sonarqube-namespace.metadata[0].name
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
