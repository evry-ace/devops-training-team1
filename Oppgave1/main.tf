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

resource "azurerm_subnet" "frontend" {
  name                 = "frontend"
  address_prefix       = "10.0.1.0/24"
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_subnet_network_security_group_association" "frontend" {
  subnet_id                 = azurerm_subnet.frontend.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "backend" {
  name                 = "backend"
  address_prefix       = "10.0.2.0/24"
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_subnet_network_security_group_association" "backend" {
  subnet_id                 = azurerm_subnet.backend.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "database" {
  name                 = "database"
  address_prefix       = "10.0.3.0/24"
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_subnet_network_security_group_association" "database" {
  subnet_id                 = azurerm_subnet.database.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = var.location
  resource_group_name = var.resource_group

  security_rule {
    name                       = "sshrule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_rule" "frontendhttp" {
  name                        = "Port_Internet_80"
  priority                    = 330
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = azurerm_public_ip.pip.ip_address
  resource_group_name         = var.resource_group
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_public_ip" "pip" {
  name                = "lbpip"
  location            = var.location
  resource_group_name = var.resource_group
  allocation_method   = "Static"
}

resource "azurerm_lb" "frontend" {
  name                = "frontend-lb"
  location            = var.location
  resource_group_name = var.resource_group

  frontend_ip_configuration {
    name                 = "frontendIPAddress"
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}

resource "azurerm_lb" "backend" {
  name                = "backend-lb"
  location            = var.location
  resource_group_name = var.resource_group

  frontend_ip_configuration {
    name      = "backendIPAddress"
    subnet_id = azurerm_subnet.backend.id
  }
}

resource "azurerm_lb" "database" {
  name                = "database-lb"
  location            = var.location
  resource_group_name = var.resource_group

  frontend_ip_configuration {
    name      = "databaseIPAddress"
    subnet_id = azurerm_subnet.database.id
  }
}

module "frontend" {
  source             = "./cluster"
  name               = "frontend"
  location           = var.location
  resource_group     = var.resource_group
  subnet_frontend_id = azurerm_subnet.frontend.id
  port               = 80
  loadbalancer_id    = azurerm_lb.frontend.id
}

module "backend" {
  source             = "./cluster"
  name               = "backend"
  location           = var.location
  resource_group     = var.resource_group
  subnet_frontend_id = azurerm_subnet.backend.id
  port               = 80
  loadbalancer_id    = azurerm_lb.backend.id
}

module "database" {
  source             = "./cluster"
  name               = "database"
  location           = var.location
  resource_group     = var.resource_group
  subnet_frontend_id = azurerm_subnet.database.id
  port               = 5432
  loadbalancer_id    = azurerm_lb.database.id
}