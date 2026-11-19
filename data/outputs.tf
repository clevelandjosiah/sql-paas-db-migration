output "resource_group_name" {
  value = azurerm_resource_group.data.name
}

output "name_suffix" {
  value = local.suffix
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.sql.fully_qualified_domain_name
}

output "sql_database_id" {
  description = "Used in Phase 6 to query metrics"
  value       = azurerm_mssql_database.app.id
}

output "key_vault_uri" {
  value = azurerm_key_vault.kv.vault_uri
}
