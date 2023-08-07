
resource "azurerm_recovery_services_vault" "vault" {
  name                = "AzureLABRecoveryVault"
  location            = azurerm_resource_group.IAAC_Infra.location
  resource_group_name = azurerm_resource_group.IAAC_Infra.name
  sku                 = "Standard"
  soft_delete_enabled = true

  tags = {
    environment = "AzureLAB"
}

}

