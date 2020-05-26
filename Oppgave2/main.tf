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


provider "kubernetes" {
  load_config_file = "false"

  host = azurerm_kubernetes_cluster.example.kube_config.0.host

  client_certificate = base64decode(azurerm_kubernetes_cluster.example.kube_config.0.client_certificate)

  client_key = base64decode(azurerm_kubernetes_cluster.example.kube_config.0.client_key)

  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.example.kube_config.0.cluster_ca_certificate)

}

resource "kubernetes_pod" "nginxpod" {
  metadata {
    name = "nginxpod"
    labels = {
      App = "Mynginxapp"
    }
  }

  spec {
    container {
      image = "nginx:1.7.8"
      name  = "example"

      port {
        container_port = 80
      }
    }
  }
}

resource "kubernetes_service" "nginx" {
  metadata {
    name = "nginx-example"
  }
  spec {
    selector = {
      App = kubernetes_pod.nginxpod.metadata[0].labels.App
    }
    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "scalable-nginx-example"
    labels = {
      App = "ScalableNginxExample"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        App = "ScalableNginxExample"
      }
    }
    template {
      metadata {
        labels = {
          App = "ScalableNginxExample"
        }
      }
      spec {
        container {
          image = "nginx:1.7.8"
          name  = "example"

          port {
            container_port = 80
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
        }
      }
    }
  }
}

resource "kubernetes_service" "scalablenginx" {
  metadata {
    name = "scalable-nginx-svc"
  }
  spec {
    selector = {
      App = kubernetes_deployment.nginx.spec.0.template.0.metadata[0].labels.App
    }
    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}


resource "kubernetes_ingress" "nginx_ingress" {
  metadata {
    name = "nginx-ingress"
  }

  spec {
    backend {
      service_name = kubernetes_service.scalablenginx.name
      service_port = kubernetes_service.scalablenginx.port
    }

    rule {
      http {
        path {
          backend {
            service_name = kubernetes_service.scalablenginx.name
            service_port = kubernetes_service.scalablenginx.port
          }

          path = "/my-local-chart/*"
        }
      }
    }
  }
}

/* provider "helm" {
  kubernetes {
    # config_path = "/path/to/kube_cluster.yaml"
    config_path = azurerm_kubernetes_cluster.example.kube_config_raw
  }
} */

provider "helm" {
  kubernetes {
    load_config_file       = "false"
    host                   = azurerm_kubernetes_cluster.example.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.example.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.example.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.example.kube_config.0.cluster_ca_certificate)
    /*     host     = "https://104.196.242.174"
    username = "ClusterMaster"
    password = "MindTheGap"

    client_certificate     = file("~/.kube/client-cert.pem")
    client_key             = file("~/.kube/client-key.pem")
    cluster_ca_certificate = file("~/.kube/cluster-ca-cert.pem") */
  }
}

data "helm_repository" "traefik" {
  name = "traefik"
  url  = "https://containous.github.io/traefik-helm-chart"
}

resource "helm_release" "traefik" {
  name       = "traefik"
  repository = data.helm_repository.traefik.metadata[0].name
  chart      = "traefik/traefik"
  namespace  = "kube-system"

  #--set="logs.loglevel=DEBUG"
  set {
    name  = "logs.loglevel"
    value = "INFO"
  }
}


resource "helm_release" "local" {
  name  = "my-local-chart"
  chart = "./team1-chart"

  #--set ingress.paths[0]=/fo-path
  set {
    name  = "ingress.paths[0]"
    value = "/my-local-chart"
  }
}