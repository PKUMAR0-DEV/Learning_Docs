provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "rg-kkt-9955-vm" {
  name     = "cheap-linux-docker-rsg"
  location = "East US"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "cheap-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg-kkt-9955-vm.location
  resource_group_name = azurerm_resource_group.rg-kkt-9955-vm.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "cheap-subnet"
  resource_group_name  = azurerm_resource_group.rg-kkt-9955-vm.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "cheap-nsg"
  location            = azurerm_resource_group.rg-kkt-9955-vm.location
  resource_group_name = azurerm_resource_group.rg-kkt-9955-vm.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
    security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  security_rule {
    name                       = "Jenkins"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}



resource "azurerm_public_ip" "public_ip" {
  name                = "cheap-public-ip"
  location            = azurerm_resource_group.rg-kkt-9955-vm.location
  resource_group_name = azurerm_resource_group.rg-kkt-9955-vm.name
  allocation_method   = "Static" # 💸 Static IP for SSH access
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic" {
  name                = "cheap-nic"
  location            = azurerm_resource_group.rg-kkt-9955-vm.location
  resource_group_name = azurerm_resource_group.rg-kkt-9955-vm.name

  ip_configuration {
    name                          = "cheap-ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "cheap_vm" {
  name                  = "cheap-docker-vm"
  resource_group_name   = azurerm_resource_group.rg-kkt-9955-vm.name
  location              = azurerm_resource_group.rg-kkt-9955-vm.location
  size                  = "Standard_B1s" # 💸 Cheapest general-purpose VM
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.nic.id]
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("/home/prudra/.ssh/azure_vm_key.pub") # 👈 Use your own key here
  }

source_image_reference {
  publisher = "Canonical"
  offer     = "0001-com-ubuntu-server-focal"
  sku       = "20_04-lts"
  version   = "latest"
}

  os_disk {
    name                 = "cheap-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  custom_data = filebase64("${path.module}/cloud-init.yaml") # 🐳 Docker install
}
