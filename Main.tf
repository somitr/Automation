resource "azurerm_resource_group" "IAAC_Infra" {

  name     = "AzureLAB"
  location = "East US"

  tags = {
    environment = "AzureLAB"
     }
}
##VNET
resource "azurerm_virtual_network" "IAAC_Infra_VNET" {
  name                = "AzureLAB_VNET"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.IAAC_Infra.location
  resource_group_name = azurerm_resource_group.IAAC_Infra.name
}

##Subnets
resource "azurerm_subnet" "IAAC_Infra_Subnet_DC" {
  name                 = "DC_Subnet"
  resource_group_name  = azurerm_resource_group.IAAC_Infra.name
  virtual_network_name = azurerm_virtual_network.IAAC_Infra_VNET.name
  address_prefixes     = ["10.1.1.0/28"]
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_subnet" "IAAC_Infra_Subnet_SH" {
  name                 = "SH_Subnet"
  resource_group_name  = azurerm_resource_group.IAAC_Infra.name
  virtual_network_name = azurerm_virtual_network.IAAC_Infra_VNET.name
  address_prefixes     = ["10.1.2.0/24"]
}

resource "azurerm_subnet" "IAAC_Infra_Subnet_Jump" {
  name                 = "Jump_Subnet"
  resource_group_name  = azurerm_resource_group.IAAC_Infra.name
  virtual_network_name = azurerm_virtual_network.IAAC_Infra_VNET.name
  address_prefixes     = ["10.1.3.0/28"]
}

##Storage account
resource "azurerm_storage_account" "AzureLABStorage" {
  name                 = "somitr2023storage"
  resource_group_name  = azurerm_resource_group.IAAC_Infra.name
  location             = azurerm_resource_group.IAAC_Infra.location
  account_tier         = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "VHDShare" {
  name                 = "vhdsharesomitr"
  storage_account_name = azurerm_storage_account.AzureLABStorage.name
  quota                = 50
}

##Jump_VM
resource "azurerm_public_ip" "JumpVM_pip" {
  name                    = "JumpVMPIP"
  location                = azurerm_resource_group.IAAC_Infra.location
  resource_group_name     = azurerm_resource_group.IAAC_Infra.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30
}

resource "azurerm_network_interface" "nic1" {
  name                = "JumpVMNIC"
  location            = azurerm_resource_group.IAAC_Infra.location
  resource_group_name = azurerm_resource_group.IAAC_Infra.name

  ip_configuration {
    name                          = "internalJumpVMIP"
    subnet_id                     = azurerm_subnet.IAAC_Infra_Subnet_Jump.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.JumpVM_pip.id
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = "AzureLAB_NSG"
  location            = "East US"
  resource_group_name = azurerm_resource_group.IAAC_Infra.name

  security_rule {
    name                       = "RDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "nic1-nsg" {
  network_interface_id      = azurerm_network_interface.nic1.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_windows_virtual_machine" "vm1" {
  name                = "JumpVM"
  resource_group_name = azurerm_resource_group.IAAC_Infra.name
  location            = azurerm_resource_group.IAAC_Infra.location
  size                = "Standard_B2s"
  admin_username      = "azurefixmylab"
  admin_password      = "P@ssw0rd12345"
  network_interface_ids = [
    azurerm_network_interface.nic1.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-21h2-avd"
    version   = "latest"
}

tags = {
    environment = "AzureLAB"
}

}

##DC_VM
resource "azurerm_network_interface" "nic2" {
  name                = "DCVMNIC"
  location            = azurerm_resource_group.IAAC_Infra.location
  resource_group_name = azurerm_resource_group.IAAC_Infra.name

  ip_configuration {
    name                          = "internalDCVMIP"
    subnet_id                     = azurerm_subnet.IAAC_Infra_Subnet_DC.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "nic2-nsg" {
  network_interface_id      = azurerm_network_interface.nic2.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_windows_virtual_machine" "vm2" {
  name                = "DCVM"
  resource_group_name = azurerm_resource_group.IAAC_Infra.name
  location            = azurerm_resource_group.IAAC_Infra.location
  size                = "Standard_B2s"
  admin_username      = "azurefixmylab"
  admin_password      = "P@ssw0rd12345"
  network_interface_ids = [
    azurerm_network_interface.nic2.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-datacenter-gensecond"
    version   = "latest"
  }

tags = {
    environment = "AzureLAB"
}

}

##SH1
resource "azurerm_network_interface" "nic3" {
  name                = "SH1VMNIC"
  location            = azurerm_resource_group.IAAC_Infra.location
  resource_group_name = azurerm_resource_group.IAAC_Infra.name

  ip_configuration {
    name                          = "internalSH1VMIP"
    subnet_id                     = azurerm_subnet.IAAC_Infra_Subnet_SH.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "nic3-nsg" {
  network_interface_id      = azurerm_network_interface.nic3.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_windows_virtual_machine" "vm3" {
  name                = "SH1VM"
  resource_group_name = azurerm_resource_group.IAAC_Infra.name
  location            = azurerm_resource_group.IAAC_Infra.location
  size                = "Standard_B2s"
  admin_username      = "azurefixmylab"
  admin_password      = "P@ssw0rd12345"
  network_interface_ids = [
    azurerm_network_interface.nic3.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-21h2-avd"
    version   = "latest"
}

tags = {
    environment = "AzureLAB"
 }
}

##SH2
resource "azurerm_network_interface" "nic4" {
  name                = "SH2VMNIC"
  location            = azurerm_resource_group.IAAC_Infra.location
  resource_group_name = azurerm_resource_group.IAAC_Infra.name

  ip_configuration {
    name                          = "internalSH2VMIP"
    subnet_id                     = azurerm_subnet.IAAC_Infra_Subnet_SH.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "nic4-nsg" {
  network_interface_id      = azurerm_network_interface.nic4.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_windows_virtual_machine" "vm4" {
  name                = "SH2VM"
  resource_group_name = azurerm_resource_group.IAAC_Infra.name
  location            = azurerm_resource_group.IAAC_Infra.location
  size                = "Standard_B2s"
  admin_username      = "azurefixmylab"
  admin_password      = "P@ssw0rd12345"
  network_interface_ids = [
    azurerm_network_interface.nic4.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-21h2-avd"
    version   = "latest"
}

tags = {
    environment = "AzureLAB"
  }
}

##Server1
resource "azurerm_network_interface" "nic5" {
  name                = "ServerVMNIC"
  location            = azurerm_resource_group.IAAC_Infra.location
  resource_group_name = azurerm_resource_group.IAAC_Infra.name

  ip_configuration {
    name                          = "internalServerVMIP"
    subnet_id                     = azurerm_subnet.IAAC_Infra_Subnet_SH.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "nic5-nsg" {
  network_interface_id      = azurerm_network_interface.nic5.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_windows_virtual_machine" "vm5" {
  name                = "Server1VM"
  resource_group_name = azurerm_resource_group.IAAC_Infra.name
  location            = azurerm_resource_group.IAAC_Infra.location
  size                = "Standard_B2s"
  admin_username      = "azurefixmylab"
  admin_password      = "P@ssw0rd12345"
  network_interface_ids = [
    azurerm_network_interface.nic5.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-datacenter-gensecond"
    version   = "latest"
  }

tags = {
    environment = "AzureLAB"
}

}

##Server2
resource "azurerm_network_interface" "nic6" {
  name                = "Server2VMNIC"
  location            = azurerm_resource_group.IAAC_Infra.location
  resource_group_name = azurerm_resource_group.IAAC_Infra.name

  ip_configuration {
    name                          = "internalServer2VMIP"
    subnet_id                     = azurerm_subnet.IAAC_Infra_Subnet_SH.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "nic6-nsg" {
  network_interface_id      = azurerm_network_interface.nic6.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_windows_virtual_machine" "vm6" {
  name                = "Server2VM"
  resource_group_name = azurerm_resource_group.IAAC_Infra.name
  location            = azurerm_resource_group.IAAC_Infra.location
  size                = "Standard_B2s"
  admin_username      = "azurefixmylab"
  admin_password      = "P@ssw0rd12345"
  network_interface_ids = [
    azurerm_network_interface.nic6.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-datacenter-gensecond"
    version   = "latest"
  }

tags = {
    environment = "AzureLAB"
}

}

##Server3
resource "azurerm_network_interface" "nic7" {
  name                = "Server3VMNIC"
  location            = azurerm_resource_group.IAAC_Infra.location
  resource_group_name = azurerm_resource_group.IAAC_Infra.name

  ip_configuration {
    name                          = "internalServer3VMIP"
    subnet_id                     = azurerm_subnet.IAAC_Infra_Subnet_SH.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "nic7-nsg" {
  network_interface_id      = azurerm_network_interface.nic7.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_windows_virtual_machine" "vm7" {
  name                = "Server3VM"
  resource_group_name = azurerm_resource_group.IAAC_Infra.name
  location            = azurerm_resource_group.IAAC_Infra.location
  size                = "Standard_B2s"
  admin_username      = "azurefixmylab"
  admin_password      = "P@ssw0rd12345"
  network_interface_ids = [
    azurerm_network_interface.nic7.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-datacenter-gensecond"
    version   = "latest"
  }

tags = {
    environment = "AzureLAB"
}

}

##Server4
resource "azurerm_network_interface" "nic8" {
  name                = "Server4VMNIC"
  location            = azurerm_resource_group.IAAC_Infra.location
  resource_group_name = azurerm_resource_group.IAAC_Infra.name

  ip_configuration {
    name                          = "internalServer4VMIP"
    subnet_id                     = azurerm_subnet.IAAC_Infra_Subnet_SH.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "nic8-nsg" {
  network_interface_id      = azurerm_network_interface.nic8.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_windows_virtual_machine" "vm8" {
  name                = "Server4VM"
  resource_group_name = azurerm_resource_group.IAAC_Infra.name
  location            = azurerm_resource_group.IAAC_Infra.location
  size                = "Standard_B2s"
  admin_username      = "azurefixmylab"
  admin_password      = "P@ssw0rd12345"
  network_interface_ids = [
    azurerm_network_interface.nic8.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-datacenter-gensecond"
    version   = "latest"
  }

tags = {
    environment = "AzureLAB"
}

}