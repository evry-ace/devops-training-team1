resource "azurerm_virtual_machine" "main" {
  name                  = "${var.vm_name}-${format("%02d", count.index+1)}"
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = ["${element(azurerm_network_interface.main.*.id, count.index)}"]
  vm_size               = "Standard_B1ms"
  count                 = var.vm_count

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.vm_name}osdisk-${format("%02d", count.index+1)}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = var.username
    admin_password = var.password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_network_interface" "main" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = ["${element(azurerm_public_ip.main.*.id, count.index)}"]
  }
}

resource "azurerm_public_ip" "main" {
  name                = "${var.vm_name}-pip-${format("%02d", count.index+1)}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
}

resource "azurerm_virtual_machine_extension" "main" {
  count                = var.add_nginx ? 1 : 0
  name                 = "nginx"
  virtual_machine_id   = ["${element(azurerm_virtual_machine.main.*.id, count.index)}"]
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  protected_settings = <<PROT
    {
        "script": "${base64encode(file("${path.module}/user_data.sh"))}"
    }
    PROT

}
