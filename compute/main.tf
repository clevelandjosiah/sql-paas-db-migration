# Compute layer: rg-webapp-compute-dev
# Step 0 builds everything here. Phase 1 deletes the vm-db-01 section.
# Phase 5 (Part A) turns on vm-web-01's managed identity.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id

  features {
    virtual_machine {
      # Phase 1: destroying vm-db-01 also deletes its OS disk
      delete_os_disk_on_deletion = true
    }
  }
}

locals {
  workload    = "webapp"
  environment = "dev"
}

# ---------------------------------------------------------------
# Resource group and network
# ---------------------------------------------------------------

resource "azurerm_resource_group" "compute" {
  name     = "rg-${local.workload}-compute-${local.environment}"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.workload}-${local.environment}"
  location            = azurerm_resource_group.compute.location
  resource_group_name = azurerm_resource_group.compute.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.compute.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "web" {
  name                = "nsg-web"
  location            = azurerm_resource_group.compute.location
  resource_group_name = azurerm_resource_group.compute.name

  security_rule {
    name                       = "Allow-SSH-From-Client"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.client_ip
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}

# ---------------------------------------------------------------
# vm-web-01 (kept for the whole lab)
# ---------------------------------------------------------------

resource "azurerm_public_ip" "web" {
  name                = "vm-web-01-pip"
  location            = azurerm_resource_group.compute.location
  resource_group_name = azurerm_resource_group.compute.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "web" {
  name                = "vm-web-01-nic"
  location            = azurerm_resource_group.compute.location
  resource_group_name = azurerm_resource_group.compute.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web.id
  }
}

resource "azurerm_linux_virtual_machine" "web" {
  name                            = "vm-web-01"
  location                        = azurerm_resource_group.compute.location
  resource_group_name             = azurerm_resource_group.compute.name
  size                            = "Standard_B1s"
  admin_username                  = var.vm_admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.web.id]

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = file(pathexpand(var.ssh_public_key_path))
  }

  os_disk {
    name                 = "vm-web-01_OsDisk_1"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Phase 5, Part A: system-assigned managed identity.
  # Off until enable_web_identity = true in terraform.tfvars.
  dynamic "identity" {
    for_each = var.enable_web_identity ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }
}

# ===============================================================
# BEGIN vm-db-01: PHASE 1 deletes everything from here to END
# ===============================================================

resource "azurerm_network_interface" "db" {
  name                = "vm-db-01-nic"
  location            = azurerm_resource_group.compute.location
  resource_group_name = azurerm_resource_group.compute.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "db" {
  name                            = "vm-db-01"
  location                        = azurerm_resource_group.compute.location
  resource_group_name             = azurerm_resource_group.compute.name
  size                            = "Standard_B1s"
  admin_username                  = var.vm_admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.db.id]

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = file(pathexpand(var.ssh_public_key_path))
  }

  os_disk {
    name                 = "vm-db-01_OsDisk_1"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# ===============================================================
# END vm-db-01
# ===============================================================
