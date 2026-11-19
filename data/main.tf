# Data layer: rg-webapp-data-dev
# Phases 2 to 4 are built in one apply: SQL, Key Vault, your admin role, the secret.
# Phase 5 (Part B) adds vm-web-01's role assignment when grant_vm_access = true.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id

  features {
    key_vault {
      # Cleanup: purge the soft-deleted vault on terraform destroy
      purge_soft_delete_on_destroy = true
    }
  }
}

data "azurerm_client_config" "current" {}

locals {
  workload    = "webapp"
  environment = "dev"
  suffix      = random_string.suffix.result
}

# Globally unique names need a suffix. Generated once and kept in state.
resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
  numeric = true
}

# Look up vm-web-01 from the compute layer by name (separate state)
data "azurerm_virtual_machine" "web" {
  name                = "vm-web-01"
  resource_group_name = "rg-${local.workload}-compute-${local.environment}"
}

resource "azurerm_resource_group" "data" {
  name     = "rg-${local.workload}-data-${local.environment}"
  location = var.location
}

# ---------------------------------------------------------------
# Phase 2: Azure SQL Database (PaaS)
# ---------------------------------------------------------------

resource "azurerm_mssql_server" "sql" {
  name                          = "sql-${local.workload}-${local.environment}-${local.suffix}"
  location                      = azurerm_resource_group.data.location
  resource_group_name           = azurerm_resource_group.data.name
  version                       = "12.0"
  administrator_login           = "sqladmin"
  administrator_login_password  = var.sql_admin_password
  minimum_tls_version           = "1.2"
  public_network_access_enabled = true

  # SQL authentication only: no azuread_administrator block.
  # Defender for SQL: not configured ("Not now").
}

resource "azurerm_mssql_database" "app" {
  name                 = "sqldb-${local.workload}"
  server_id            = azurerm_mssql_server.sql.id
  sku_name             = "Basic"
  max_size_gb          = 2
  collation            = "SQL_Latin1_General_CP1_CI_AS"
  storage_account_type = "Local" # Locally-redundant backup storage (LRS)
}

# "Allow Azure services and resources to access this server" = Yes
resource "azurerm_mssql_firewall_rule" "allow_azure" {
  name             = "AllowAllWindowsAzureIps"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# "Add current client IP address" = Yes
resource "azurerm_mssql_firewall_rule" "client_ip" {
  name             = "ClientIP"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = var.client_ip
  end_ip_address   = var.client_ip
}

# ---------------------------------------------------------------
# Phase 3: Azure Key Vault, plus Key Vault Administrator for you
# ---------------------------------------------------------------

resource "azurerm_key_vault" "kv" {
  name                          = "kv-${local.workload}-${local.environment}-${local.suffix}"
  location                      = azurerm_resource_group.data.location
  resource_group_name           = azurerm_resource_group.data.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  enable_rbac_authorization     = true  # Permission model: Azure RBAC
  soft_delete_retention_days    = 90
  purge_protection_enabled      = false # Leave off so cleanup works
  public_network_access_enabled = true

  enabled_for_deployment          = false
  enabled_for_template_deployment = false
  enabled_for_disk_encryption     = false

  network_acls {
    default_action = "Allow" # All networks
    bypass         = "AzureServices"
  }
}

resource "azurerm_role_assignment" "me_kv_admin" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# RBAC takes a minute or two to apply before you can write secrets
resource "time_sleep" "wait_for_rbac" {
  depends_on      = [azurerm_role_assignment.me_kv_admin]
  create_duration = "90s"
}

# ---------------------------------------------------------------
# Phase 4: store the SQL admin password as a secret
# ---------------------------------------------------------------

resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "SqlAdminPassword"
  value        = var.sql_admin_password
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [time_sleep.wait_for_rbac]
}

# ---------------------------------------------------------------
# Phase 5, Part B: vm-web-01's identity gets read access to secrets
# ---------------------------------------------------------------

resource "azurerm_role_assignment" "vm_secrets_user" {
  count = var.grant_vm_access ? 1 : 0

  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = try(data.azurerm_virtual_machine.web.identity[0].principal_id, "")

  lifecycle {
    precondition {
      condition     = try(data.azurerm_virtual_machine.web.identity[0].principal_id, "") != ""
      error_message = "vm-web-01 has no managed identity yet. Apply compute with enable_web_identity = true first."
    }
  }
}
