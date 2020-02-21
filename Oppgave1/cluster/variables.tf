variable "name" {
  description = "Name used when creating resources"
}

variable "port" {
  default     = 80
  description = "Ports for probe, frontend and backend in load balancer"
}


variable "resource_group" {
  default     = "devops-training-team1"
  description = "The name of the resource group in which to create the virtual network."
}

variable "location" {
  default     = "northeurope"
  description = "Location that the instances will be created"
}

variable "loadbalancer_id" {
  description = "ID of loadbalancer"
}

variable "subnet_frontend_id" {
  description = "Frontend ID of subnet"
}

variable "my_ssh_key" {
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDDOphCHThzsgraK4np2AtNZiQeru2l1gNMyqeSg9K/elaW7kWGqtcsRR3vP1zQDZbWfhhfyqARn9DEZLQFhsAt59CCc1sokmFnWUaHcANS4+3B0fbIFuBJ/i7SgKjkFRXpFoQ7NFzp9uzJ4QQ/R1+qSO80VSPYLz7sciypLphTNXScd3L/gqEBN72Rmbf5Xq5pa1HU4AzEnYd8lc/y9TlCeSs62LoXz+FzRPd8+CzIKtY/T6FAS1fh/E+haVkb8ghkBQ4NIbh7WXCgIUPu/PeM/XTQZ+N6WWI0kuSWdszYzIcVEuflWAwxg8+YXwHn0zX45uF+jRTQX2uy49DH4epeFYbHPQ8ESF/wUdd+M7ZBJQKd/FcVw/otxhK0e7B81TDgVx/Up0I+mgRCHQ45tTcHQ1aSZuLjLov5A6D7EIKdChGSxuWZI6CgQYZt39scOnZbNU0i2Qu2oNOQ8vSCABJ3jTFJUfaF0RN3eICRnwuBogXrpeBYxQm2nP1E9zkjyeSN6uaDPPNJAhztOvz2eHbMRAZjmNvy3EHs2LIntcy3hTgzBM0AzDrtnEwAPkVngPhpB1kX6kJlFZ/Qs+9X9lhQbH32rMB7NOUlJirIvoBTgA/R4LzPR5djI1+S7b1YPLBtqOhgmG9lZcbM4OwjV1mRPRtUuxYS5sWX2RESU156XQ== Generated by E217974@PC38695."
  description = "SSH key"
}



