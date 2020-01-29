variable "resource_group" {
  default     = "devops-training-team1"
  description = "The name of the resource group in which to create the virtual network."
}

variable "location" {
  default     = "northeurope"
  description = "Location that the instances will be created"
}

variable "prefix" {
  default     = "team1"
  description = "A prefix for the environment"
}

variable scfile {
  type        = string
  default     = "user_data.sh"
  description = "A script to run on vm's after it is created"
}

