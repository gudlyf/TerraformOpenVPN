################################################################################
# Infrastructure
################################################################################

variable "name" {
  description = "Name prefix for all resources."
  type        = string
  default     = "openvpn"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,31}$", var.name))
    error_message = "name must be 1-32 characters of lowercase letters, digits or '-' and start with a letter."
  }
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "westus2"
}

variable "resource_group_name" {
  description = "Name of the resource group to create. Defaults to \"rg-<name>\"."
  type        = string
  default     = null
}

variable "vm_size" {
  description = "VM size."
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin user on the VM."
  type        = string
  default     = "ubuntu"
}

variable "source_image" {
  description = "Marketplace image for the VM. Defaults to Canonical Ubuntu 24.04 LTS (x64, Gen2)."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

variable "vnet_cidr" {
  description = "Address space of the virtual network. Must not overlap vpn_cidr."
  type        = string
  default     = "10.10.0.0/24"

  validation {
    condition     = can(cidrnetmask(var.vnet_cidr))
    error_message = "vnet_cidr must be an IPv4 CIDR block."
  }
}

variable "domain_name_label" {
  description = "DNS label for the public IP (<label>.<location>.cloudapp.azure.com). Defaults to \"<name>-<random>\"."
  type        = string
  default     = null
}

variable "vpn_allowed_cidrs" {
  description = "IPv4 CIDR blocks allowed to reach the VPN port."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.vpn_allowed_cidrs) > 0 && alltrue([for c in var.vpn_allowed_cidrs : can(cidrnetmask(c))])
    error_message = "vpn_allowed_cidrs must contain at least one IPv4 CIDR block, e.g. 203.0.113.4/32."
  }
}

variable "ssh_public_key" {
  description = "OpenSSH public key for admin_username. If null, a throwaway key is generated (Azure requires one) and SSH stays closed."
  type        = string
  default     = null
}

variable "ssh_allowed_cidrs" {
  description = "IPv4 CIDR blocks allowed to SSH to the VM. Empty (the default) means port 22 is closed."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for c in var.ssh_allowed_cidrs : can(cidrnetmask(c))])
    error_message = "ssh_allowed_cidrs must contain IPv4 CIDR blocks, e.g. 203.0.113.4/32."
  }
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# OpenVPN (passed through to modules/openvpn-config)
################################################################################

variable "clients" {
  description = "Client names to issue .ovpn profiles for. Removing a name revokes that client."
  type        = set(string)
  default     = ["client"]
}

variable "vpn_port" {
  description = "Port OpenVPN listens on."
  type        = number
  default     = 1194
}

variable "vpn_protocol" {
  description = "\"udp\" (recommended) or \"tcp\"."
  type        = string
  default     = "udp"
}

variable "vpn_cidr" {
  description = "IPv4 network handed out to VPN clients."
  type        = string
  default     = "10.8.0.0/24"
}

variable "dns_servers" {
  description = "DNS servers pushed to clients."
  type        = list(string)
  default     = ["1.1.1.1", "9.9.9.9"]
}

variable "full_tunnel" {
  description = "Route all client traffic through the VPN."
  type        = bool
  default     = true
}

variable "pushed_routes" {
  description = "Extra IPv4 CIDR routes pushed to clients."
  type        = list(string)
  default     = []
}

variable "cert_subject" {
  description = "Certificate subject fields (organization, organizational_unit, country, province, locality)."
  type = object({
    organization        = optional(string, "TerraformOpenVPN")
    organizational_unit = optional(string)
    country             = optional(string)
    province            = optional(string)
    locality            = optional(string)
  })
  default = {}
}

variable "client_config_dir" {
  description = "Directory to write .ovpn files to. Null disables writing files."
  type        = string
  default     = null
}

variable "client_config_prefix" {
  description = "Prefix for generated .ovpn file names."
  type        = string
  default     = "azure-"
}
