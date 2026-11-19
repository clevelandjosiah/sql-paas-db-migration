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
  description = "Your public IP, allowed to SSH to vm-web-01"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to your SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "vm_admin_username" {
  description = "Admin username for the Linux VMs"
  type        = string
  default     = "azureuser"
}

variable "enable_web_identity" {
  description = "Phase 5, Part A: set to true to turn on vm-web-01's system-assigned identity"
  type        = bool
  default     = false
}
