variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "client_ip" {
  description = "Your public IP, added to the SQL firewall"
  type        = string
}

variable "sql_admin_password" {
  description = "SQL admin password. Set it with: export TF_VAR_sql_admin_password='...'"
  type        = string
  sensitive   = true
}

variable "grant_vm_access" {
  description = "Phase 5, Part B: set to true to give vm-web-01 Key Vault Secrets User"
  type        = bool
  default     = false
}
