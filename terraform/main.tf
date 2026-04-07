terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Number of Vms
variable  "vm_count" {
  default = 2 
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "multi-play-web-deploy"
  location = "centralus" 
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "myVNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Subnets
resource "azurerm_subnet" "subnet" {
  name                   = "mySubnet"
  address_prefixes       = ["10.0.1.0/24"]
  virtual_network_name   = azurerm_virtual_network.vnet.name
  resource_group_name    = azurerm_resource_group.rg.name
}

# Public IP (multiple) 2 IPs
resource "azurerm_public_ip" "public_ip" {
 count                = var.vm_count
  name                = "myPublicIP${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Network Interface (multiple) 2 NICs 
resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "myNIC${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "myIPConfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip[count.index].id
  }
}

# Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "vm-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

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
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Attach NSG to Subnet
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                    = azurerm_subnet.subnet.id
  network_security_group_id    = azurerm_network_security_group.nsg.id
}

# Linux Virtual Machine (multiple) 2 VMs
resource "azurerm_linux_virtual_machine" "vm" {
  count               = var.vm_count
  name                = "myLinuxVM${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_D2s_v3"  # Standrad_B1s

  admin_username      = "azureuser"

  disable_password_authentication = true

  admin_ssh_key {
    username     = "azureuser"
    public_key = file(var.public_key_path)
  }

  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-LTS"
    version   = "latest"
  }
}

# Output all public IPS
output "public_ip_addresses" {
  value = azurerm_public_ip.public_ip[*].ip_address  # 2 public IPs
}


