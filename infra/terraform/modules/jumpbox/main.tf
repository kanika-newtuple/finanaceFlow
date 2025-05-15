# Jumpbox VM for accessing the private AKS cluster
resource "azurerm_subnet" "jumpbox_subnet" {
  name                 = "jumpbox-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = [var.jumpbox_subnet_cidr]
}

resource "azurerm_network_security_group" "jumpbox_nsg" {
  name                = "${var.prefix}-${var.environment}-jumpbox-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  depends_on = [azurerm_subnet.jumpbox_subnet]

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.allowed_ssh_source_ips
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "jumpbox_nsg_association" {
  subnet_id                 = azurerm_subnet.jumpbox_subnet.id
  network_security_group_id = azurerm_network_security_group.jumpbox_nsg.id

  depends_on = [azurerm_network_security_group.jumpbox_nsg]
}

resource "azurerm_public_ip" "jumpbox_ip" {
  name                = "${var.prefix}-${var.environment}-jumpbox-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  tags                = var.tags

  depends_on = [azurerm_subnet_network_security_group_association.jumpbox_nsg_association]
}

resource "azurerm_network_interface" "jumpbox_nic" {
  name                = "${var.prefix}-${var.environment}-jumpbox-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  depends_on = [azurerm_public_ip.jumpbox_ip]

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.jumpbox_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jumpbox_ip.id
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                = "${var.prefix}-${var.environment}-jumpbox"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.jumpbox_vm_size
  admin_username      = var.jumpbox_admin_username
  network_interface_ids = [
    azurerm_network_interface.jumpbox_nic.id,
  ]

  depends_on = [azurerm_network_interface.jumpbox_nic]
  
  admin_ssh_key {
    username   = var.jumpbox_admin_username
    public_key = var.jumpbox_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  # Setup script for the jumpbox
  custom_data = base64encode(templatefile(var.jumpbox_setup_script_path, {
    RESOURCE_GROUP = var.resource_group_name
    ADMIN_USERNAME = var.jumpbox_admin_username
    TENANT_ID      = var.tenant_id
  }))

  tags = var.tags
}
