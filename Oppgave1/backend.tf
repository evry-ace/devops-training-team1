terraform {
  backend "azurerm" {
    storage_account_name = "devopsteam1storage"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"

    # rather than defining this inline, the Access Key can also be sourced
    # from an Environment Variable - more information is available below.
    access_key = "xynhek189qVKUtKiClvD4JlDneOCmiKwvTYDDz6JhNZCgnTNBfKxtx3weT166CIgVfg8m5rQ7g1/krl4kNKDPA=="
  }
}