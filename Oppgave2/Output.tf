output "client_certificate" {
  value = azurerm_kubernetes_cluster.example.kube_config.0.client_certificate
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.example.kube_config_raw
}

output "lb_ip" {
  value = kubernetes_service.nginx.load_balancer_ingress[0].ip
}

output "lb_ip" {
  value = kubernetes_service.scalablenginx.load_balancer_ingress[0].ip
}