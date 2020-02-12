output "ip_address" {
  value = azurerm_public_ip.main.ip_address
}

output "instance_ips" {
  value = ["${azurerm_public_ip.main.*.ip_address}"]
}

output "instance_interface" {
  value = ["${azurerm_network_interface.main.*.id}"]
}
