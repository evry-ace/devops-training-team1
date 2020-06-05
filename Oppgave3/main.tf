provider "azurerm" {
  # version = "=2.0.0"
  #
  features {}
}

data "azurerm_resource_group" "example" {
  name = "devops-training-team1"
}

data "azurerm_kubernetes_cluster" "example" {
  name                = "example-aks1"
  resource_group_name = data.azurerm_resource_group.example.name
}

provider "kubernetes" {
  load_config_file = "false"

  host = data.azurerm_kubernetes_cluster.example.kube_config.0.host

  client_certificate = base64decode(data.azurerm_kubernetes_cluster.example.kube_config.0.client_certificate)

  client_key = base64decode(data.azurerm_kubernetes_cluster.example.kube_config.0.client_key)

  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.example.kube_config.0.cluster_ca_certificate)

}

#resource "kubernetes_namespace" "prometheus" {
#  metadata {
#    name = "monitoring"
#
#    # labels = {
#    #   "istio-injection"    = "disabled"
#    #   "kiali.io/member-of" = "istio-system"
#    # }
#  }
#}

data "kubernetes_namespace" "prometheus" {
  metadata {
    name = "monitoring"
  }
}

data "template_file" "prometheus_operator_config" {
  template = file("${path.root}/config/config.yaml")
  vars = {
    external_dns_ingress_dns = "team1.kia"
    #   #istio_secret = "${true ? "[istio.default, istio.prometheus-operator-prometheus]" : "[]"}"

    #   alertmanager_tls_secret_name = "alertmanager-${replace("tietoevry.site", ".", "-")}-tls"

    #   grafana_tls_secret_name = "grafana-${replace("tietoevry.site", ".", "-")}-tls"

    #   prometheus_operator_create_crd = true
    #   prometheus_tls_secret_name     = "prometheus-${replace("tietoevry.site", ".", "-")}-tls"
    #
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
    host                   = data.azurerm_kubernetes_cluster.example.kube_config.0.host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.example.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.example.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.example.kube_config.0.cluster_ca_certificate)
    /*     host     = "https://104.196.242.174"
    username = "ClusterMaster"
    password = "MindTheGap"

    client_certificate     = file("~/.kube/client-cert.pem")
    client_key             = file("~/.kube/client-key.pem")
    cluster_ca_certificate = file("~/.kube/cluster-ca-cert.pem") */
  }
}

resource "helm_release" "prometheus-operator" {
  name       = "prometheus-operator"
  namespace  = data.kubernetes_namespace.prometheus.metadata[0].name
  repository = "https://kubernetes-charts.storage.googleapis.com"
  chart      = "prometheus-operator"
  version    = "8.13.7"

  values = [
    data.template_file.prometheus_operator_config.rendered
  ]
}

# data "helm_repository" "traefik" {
#   name = "traefik"
#   url  = "https://containous.github.io/traefik-helm-chart"
# }

# resource "helm_release" "traefik" {
#   name       = "traefik"
#   repository = data.helm_repository.traefik.metadata[0].name
#   chart      = "traefik/traefik"
#   namespace  = "kube-system"

#   #--set="logs.loglevel=DEBUG"
#   set {
#     name  = "logs.loglevel"
#     value = "INFO"
#   }
# }


# resource "helm_release" "local" {
#   name  = "my-local-chart"
#   chart = "./team1-chart"

#   #--set ingress.paths[0]=/fo-path
#   set {
#     name  = "ingress.paths[0]"
#     value = "/my-local-chart"
#   }
# }
