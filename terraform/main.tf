# Configurer le provider Azure
provider "azurerm" {
  features {}
  subscription_id = "73d2f2cc-d54a-45f4-99b2-cc8d634a82a3"
}

# Créer un groupe de ressources
resource "azurerm_resource_group" "devops_rg" {
  name     = "devops-resources"
  location = "West Europe"
}

# Créer un réseau virtuel
resource "azurerm_virtual_network" "devops_network" {
  name                = "devops-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name
}

# Créer un sous-réseau
resource "azurerm_subnet" "devops_subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.devops_rg.name
  virtual_network_name = azurerm_virtual_network.devops_network.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Créer une adresse IP publique
resource "azurerm_public_ip" "devops_public_ip" {
  name                = "devops-public-ip"
  resource_group_name = azurerm_resource_group.devops_rg.name
  location            = azurerm_resource_group.devops_rg.location
  allocation_method   = "Static"
}

# Créer un groupe de sécurité réseau et règles
resource "azurerm_network_security_group" "devops_nsg" {
  name                = "devops-nsg"
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name

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
}

# Créer une interface réseau
resource "azurerm_network_interface" "devops_nic" {
  name                = "devops-nic"
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.devops_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.devops_public_ip.id
  }
}

# Connecter l'interface réseau au groupe de sécurité
resource "azurerm_network_interface_security_group_association" "devops_sg_association" {
  network_interface_id      = azurerm_network_interface.devops_nic.id
  network_security_group_id = azurerm_network_security_group.devops_nsg.id
}

# Créer une machine virtuelle Linux avec mot de passe
resource "azurerm_linux_virtual_machine" "devops_vm" {
  name                = "devops-machine"
  resource_group_name = azurerm_resource_group.devops_rg.name
  location            = azurerm_resource_group.devops_rg.location
  size                = "Standard_B1s"
  admin_username      = var.username
  admin_password      = var.password
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.devops_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

# Output l'adresse IP publique pour se connecter à la VM
output "public_ip_address" {
  value = azurerm_public_ip.devops_public_ip.ip_address
}

# Output le nom d'utilisateur de la VM
output "vm_username" {
  value = azurerm_linux_virtual_machine.devops_vm.admin_username
}

# Output le mot de passe de la VM
output "vm_password" {
  value = azurerm_linux_virtual_machine.devops_vm.admin_password
  sensitive = true
}