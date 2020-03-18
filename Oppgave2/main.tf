provider "azurerm" {
  # version = "=2.0.0"
  features {}
}

data "azurerm_resource_group" "example" {
  name = "devops-training-team1"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
  address_space       = ["10.240.0.0/16"]
}

resource "azurerm_subnet" "Kubernetes" {
  name                 = "Kubernetes"
  address_prefix       = "10.240.1.0/24"
  resource_group_name  = data.azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_kubernetes_cluster" "example" {
  name                = "example-aks1"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
  dns_prefix          = "exampleaks1"
  kubernetes_version  = "1.14.8"

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_D2_v2"
    vnet_subnet_id = azurerm_subnet.Kubernetes.id
  }

  service_principal {
    client_id     = var.clId
    client_secret = var.clSec
  }

  tags = {
    Environment = "part1"
  }
}

resource "kubernetes_pod" "nginxpod" {
  metadata {
    name = "nginxpod"
    labels = {
      app.kubernetes.io / name = "Mynginxapp"
    }
  }

  spec {
    container {
      image = "nginx:1.7.9"
      name  = "example"

      env {
        name  = "environment"
        value = "nginxtest"
      }

      liveness_probe {
        http_get {
          path = "/nginx_status"
          port = 80

          http_header {
            name  = "X-Custom-Header"
            value = "Awesome"
          }
        }

        initial_delay_seconds = 3
        period_seconds        = 3
      }
    }

    dns_config {
      nameservers = ["1.1.1.1", "8.8.8.8", "9.9.9.9"]
      searches    = ["example.com"]

      option {
        name  = "ndots"
        value = 1
      }

      option {
        name = "use-vc"
      }
    }

    dns_policy = "None"
  }
}

