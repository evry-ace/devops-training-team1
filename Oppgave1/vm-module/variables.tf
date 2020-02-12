variable "vm_name" {
  description = "Name of the VM, will also be the name used by public IP and network interface"
}

variable "location" {
  description = "Location resources should be placed in"
  default     = "northeurope"
}

variable "resource_group_name" {
  description = "Name of resource group"
}

variable "subnet_id" {
  description = "Id of the subnet the VM should reside in"
}

variable "username" {
  description = "VM admin user name"
}

variable "password" {
  description = "Password to admin user of VM"
}

variable "add_nginx" {
  default     = false
  description = "Set to true if the VM should run an NGINX server"
}

variable "vm_count" {
  default     = 1
  description = "Number of vm to create"
}
