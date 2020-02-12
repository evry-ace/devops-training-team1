provider "azurerm" {

}

module "vnet" {
  source              = "Azure/vnet/azurerm"
  resource_group_name = var.resource_group
  location            = var.location
  address_space       = "10.0.0.0/16"
  subnet_prefixes     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  subnet_names        = ["frontend", "backend", "database"]
}

resource "azurerm_subnet" "frontend" {
  name                      = "frontend"
  address_prefix            = "10.0.1.0/24"
  resource_group_name       = var.resource_group
  virtual_network_name      = module.vnet.vnet_name
  network_security_group_id = azurerm_network_security_group.ssh.id
}

resource "azurerm_subnet" "backend" {
  name                      = "backend"
  address_prefix            = "10.0.2.0/24"
  resource_group_name       = var.resource_group
  virtual_network_name      = module.vnet.vnet_name
  network_security_group_id = azurerm_network_security_group.ssh.id
}

resource "azurerm_subnet" "database" {
  name                      = "database"
  address_prefix            = "10.0.3.0/24"
  resource_group_name       = var.resource_group
  virtual_network_name      = module.vnet.vnet_name
  network_security_group_id = azurerm_network_security_group.ssh.id
}

resource "azurerm_network_security_group" "ssh" {
  depends_on          = [module.vnet]
  name                = "ssh"
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

# resource "azurerm_network_security_group" "http" {
#   depends_on          = ["module.vnet"]
#   name                = "http"
#   location            = var.location
#   resource_group_name = var.resource_group

#   security_rule {
#     name                       = "httprule"
#     priority                   = 101
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "80"
#     source_address_prefix      = "*"
#     destination_address_prefix = "<<loadbalancer frontend subnet>>"
#   }
# }

# resource "azurerm_network_security_group" "httpinternal" {
#   depends_on          = ["module.vnet"]
#   name                = "httpinternal"
#   location            = var.location
#   resource_group_name = var.resource_group

#   security_rule {
#     name                       = "httpinternalrule"
#     priority                   = 102
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "80"
#     source_address_prefix      = "<<alle vm i frontend subnet>>"
#     destination_address_prefix = "<<loadbalancer backend subnet>>"
#   }
# }

# resource "azurerm_network_security_group" "psql" {
#   depends_on          = ["module.vnet"]
#   name                = "psql"
#   location            = var.location
#   resource_group_name = var.resource_group

#   security_rule {
#     name                       = "psqlrule"
#     priority                   = 103
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "5432"
#     destination_port_range     = "5432"
#     source_address_prefix      = "<alle vm i subnet backend>"
#     destination_address_prefix = "<loadbalancer i subnet db >"
#   }
# }

# module "vmfrontend" {
#   source              = "./vm-module"
#   vm_name             = "frontend"
#   location            = var.location
#   resource_group_name = var.resource_group
#   subnet_id           = azurerm_subnet.frontend.id
#   username            = "testadmin"
#   password            = "Password123"
#   add_nginx           = true
#   vm_count            = 3
# }

# module "vmbackend" {
#   source              = "./vm-module"
#   vm_name             = "backend"
#   location            = var.location
#   resource_group_name = var.resource_group
#   subnet_id           = azurerm_subnet.backend.id
#   username            = "testadmin"
#   password            = "Password123"
#   add_nginx           = true
#   vm_count            = 3
# }

# module "vmdatabase" {
#   source              = "./vm-module"
#   vm_name             = "database"
#   location            = var.location
#   resource_group_name = var.resource_group
#   subnet_id           = azurerm_subnet.database.id
#   username            = "testadmin"
#   password            = "Password123"
#   add_nginx           = true
#   vm_count            = 3
# }

// ------- Public LB ---------
resource "azurerm_public_ip" "pip" {
  name                = "lbpip"
  location            = var.location
  resource_group_name = var.resource_group
  allocation_method   = "Static"
}

resource "azurerm_lb" "vmss" {
  name                = "vmss-lb"
  location            = var.location
  resource_group_name = var.resource_group

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "bpepool" {
  resource_group_name = var.resource_group
  loadbalancer_id     = azurerm_lb.vmss.id
  name                = "PublicBackEndAddressPool"
}

resource "azurerm_lb_probe" "vmss" {
  resource_group_name = var.resource_group
  loadbalancer_id     = azurerm_lb.vmss.id
  name                = "http-running-probe"
  port                = 80
}

resource "azurerm_lb_rule" "lbnatrule" {
  resource_group_name            = var.resource_group
  loadbalancer_id                = azurerm_lb.vmss.id
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_id        = azurerm_lb_backend_address_pool.bpepool.id
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.vmss.id
}

resource "azurerm_virtual_machine_scale_set" "vmss" {
  name                = "vmscaleset"
  location            = var.location
  resource_group_name = var.resource_group
  upgrade_policy_mode = "Manual"

  sku {
    name     = "Standard_B1ms"
    tier     = "Standard"
    capacity = 3
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_profile_data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = 10
  }

  os_profile {
    computer_name_prefix = var.prefix
    admin_username       = "testadmin"
    admin_password       = "Password123"
  }

  os_profile_linux_config {
    disable_password_authentication = false

    ssh_keys {
      path     = "/home/testadmin/.ssh/authorized_keys"
      key_data = var.my_ssh_key
    }
  }

  network_profile {
    name    = "publicNetworkProfile"
    primary = true

    ip_configuration {
      name                                   = "PublicIPConfiguration"
      subnet_id                              = azurerm_subnet.frontend.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]
      primary                                = true
    }
  }
}

// ------- Private LB1 for backend ---------
resource "azurerm_lb" "prlb" {
  name                = "prlb-lb"
  location            = var.location
  resource_group_name = var.resource_group

  frontend_ip_configuration {
    name      = "PrivateIPAddress"
    subnet_id = azurerm_subnet.frontend.id
  }
}

resource "azurerm_lb_backend_address_pool" "privatebepool" {
  resource_group_name = var.resource_group
  loadbalancer_id     = azurerm_lb.prlb.id
  name                = "PrivateBackEndAddressPool"
}

resource "azurerm_lb_probe" "privateprobe" {
  resource_group_name = var.resource_group
  loadbalancer_id     = azurerm_lb.prlb.id
  name                = "privatehttp-running-probe"
  port                = 80
}

resource "azurerm_lb_rule" "privatelbnatrule" {
  resource_group_name            = var.resource_group
  loadbalancer_id                = azurerm_lb.prlb.id
  name                           = "phttp"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_id        = azurerm_lb_backend_address_pool.privatebepool.id
  frontend_ip_configuration_name = "PrivateIPAddress"
  probe_id                       = azurerm_lb_probe.privateprobe.id
}

resource "azurerm_virtual_machine_scale_set" "privatescaleset" {
  name                = "privatescaleset"
  location            = var.location
  resource_group_name = var.resource_group
  upgrade_policy_mode = "Manual"

  sku {
    name     = "Standard_B1ms"
    tier     = "Standard"
    capacity = 3
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_profile_data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = 10
  }

  os_profile {
    computer_name_prefix = var.prefix
    admin_username       = "testadmin"
    admin_password       = "Password123"
  }

  os_profile_linux_config {
    disable_password_authentication = false

    ssh_keys {
      path     = "/home/testadmin/.ssh/authorized_keys"
      key_data = var.my_ssh_key
    }
  }

  network_profile {
    name    = "privateNetworkProfile"
    primary = true

    ip_configuration {
      name                                   = "PrivateIPConfiguration"
      subnet_id                              = azurerm_subnet.backend.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.privatebepool.id]
      primary                                = true
    }
  }
}

// ------- Private LB2 for db ---------
resource "azurerm_lb" "dblb" {
  name                = "db-lb"
  location            = var.location
  resource_group_name = var.resource_group

  frontend_ip_configuration {
    name      = "PrivateDBIPAddress"
    subnet_id = azurerm_subnet.backend.id
  }
}

resource "azurerm_lb_backend_address_pool" "privateDBbepool" {
  resource_group_name = var.resource_group
  loadbalancer_id     = azurerm_lb.dblb.id
  name                = "PrivateDBBackEndAddressPool"
}

resource "azurerm_lb_probe" "privateDBprobe" {
  resource_group_name = var.resource_group
  loadbalancer_id     = azurerm_lb.dblb.id
  name                = "db-running-probe"
  port                = 5432
}

resource "azurerm_lb_rule" "privatedblbnatrule" {
  resource_group_name            = var.resource_group
  loadbalancer_id                = azurerm_lb.dblb.id
  name                           = "postgrs"
  protocol                       = "Tcp"
  frontend_port                  = 5432
  backend_port                   = 5432
  backend_address_pool_id        = azurerm_lb_backend_address_pool.privateDBbepool.id
  frontend_ip_configuration_name = "PrivateDBIPAddress"
  probe_id                       = azurerm_lb_probe.privateDBprobe.id
}

resource "azurerm_virtual_machine_scale_set" "dbscaleset" {
  name                = "dbscaleset"
  location            = var.location
  resource_group_name = var.resource_group
  upgrade_policy_mode = "Manual"

  sku {
    name     = "Standard_B1ms"
    tier     = "Standard"
    capacity = 3
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_profile_data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = 10
  }

  os_profile {
    computer_name_prefix = var.prefix
    admin_username       = "testadmin"
    admin_password       = "Password123"
  }

  os_profile_linux_config {
    disable_password_authentication = false

    ssh_keys {
      path     = "/home/testadmin/.ssh/authorized_keys"
      key_data = var.my_ssh_key
    }
  }

  network_profile {
    name    = "dbNetworkProfile"
    primary = true

    ip_configuration {
      name                                   = "DBIPConfiguration"
      subnet_id                              = azurerm_subnet.database.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.privateDBbepool.id]
      primary                                = true
    }
  }
}