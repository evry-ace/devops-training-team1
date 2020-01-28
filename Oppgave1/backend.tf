terraform {
  backend "azurerm" {
    storage_account_name = "devopsteam1storage"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"

  }
}