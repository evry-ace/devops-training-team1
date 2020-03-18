provider "azurerm" {
  # version = "=2.0.0"
  features {}
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  location            = var.location
  resource_group_name = var.resource_group
  address_space       = ["10.0.0.0/16"]
}