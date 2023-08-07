terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.51.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "637e301c-c39b-464e-bdd2-043795b66b09"
  client_id        = "9f8d4dd4-cb74-4d0b-a89e-0af48f27716c"
  client_secret   = "cg58Q~qJAvBspbxZ3ny2JKAVFlfEkEN5hmtv7cf3"
  tenant_id       = "d9ec7a60-484c-430a-a133-2bc3d71031d7"
  features {

  }
}