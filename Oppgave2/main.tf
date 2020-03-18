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
  address_space       = ["10.0.0.0/16"]
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
    vnet_subnet_id = azurerm_virtual_network.vnet.id
  }

  service_principal {
    client_id     = var.clId
    client_secret = var.clSec
  }

  tags = {
    Environment = "part1"
  }
}

