resource "azurerm_lb_backend_address_pool" "bpepool" {
  resource_group_name = var.resource_group
  loadbalancer_id     = var.loadbalancer_id
  name                = "${var.name}BackEndAddressPool"
}

resource "azurerm_lb_probe" "probe" {
  resource_group_name = var.resource_group
  loadbalancer_id     = var.loadbalancer_id
  name                = "http-running-probe"
  port                = var.port
}

resource "azurerm_lb_nat_pool" "natpool" {
  resource_group_name            = var.resource_group
  name                           = "ssh"
  loadbalancer_id                = var.loadbalancer_id
  protocol                       = "Tcp"
  frontend_port_start            = 50000
  frontend_port_end              = 50119
  backend_port                   = 22
  frontend_ip_configuration_name = "${var.name}IPAddress"
}

resource "azurerm_lb_rule" "lbnatrule" {
  resource_group_name            = var.resource_group
  loadbalancer_id                = var.loadbalancer_id
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = var.port
  backend_port                   = var.port
  backend_address_pool_id        = azurerm_lb_backend_address_pool.bpepool.id
  frontend_ip_configuration_name = "${var.name}IPAddress"
  probe_id                       = azurerm_lb_probe.probe.id
}

resource "azurerm_virtual_machine_scale_set" "vmss" {
  name                = "${var.name}-scaleset"
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
    computer_name_prefix = var.name
    admin_username       = "testadmin"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/testadmin/.ssh/authorized_keys"
      key_data = var.my_ssh_key
    }
  }

  network_profile {
    name    = "publicNetworkProfile"
    primary = true

    ip_configuration {
      name                                   = "${var.name}IPConfiguration"
      subnet_id                              = var.subnet_frontend_id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]
      load_balancer_inbound_nat_rules_ids    = [azurerm_lb_nat_pool.natpool.id]
      primary                                = true

    }
  }

  extension {
    name                 = "example"
    publisher            = "Microsoft.Azure.Extensions"
    type                 = "CustomScript"
    type_handler_version = "2.0"
    protected_settings   = <<PROT
     {
         "script": "${base64encode(file("${path.module}/user_data.sh"))}"
     }
     PROT
  }
}