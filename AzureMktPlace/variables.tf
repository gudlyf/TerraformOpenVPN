variable "subscription_id" {
  description = "Azure subscription ID. Null falls back to the ARM_SUBSCRIPTION_ID environment variable."
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "westus2"
}

variable "name" {
  description = "Name prefix for all resources."
  type        = string
  default     = "openvpnas"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,31}$", var.name))
    error_message = "name must be 1-32 characters of lowercase letters, digits or '-' and start with a letter."
  }
}

variable "vm_size" {
  description = "VM size."
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "OS admin user on the VM."
  type        = string
  default     = "ubuntu"
}

variable "ovpnadmin_username" {
  description = "OpenVPN Access Server admin UI user."
  type        = string
  default     = "openvpn"
}

variable "marketplace_image" {
  description = "OpenVPN Access Server marketplace image and plan."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "openvpn"
    offer     = "openvpnas"
    sku       = "openvpnas-gen2"
    version   = "latest"
  }
}

variable "accept_marketplace_terms" {
  description = "Accept the marketplace terms for the image with Terraform. Leave false if they are already accepted in this subscription (az vm image terms accept ...)."
  type        = bool
  default     = false
}

variable "vnet_cidr" {
  description = "Address space of the virtual network."
  type        = string
  default     = "192.168.50.0/24"
}

variable "subnet_cidr" {
  description = "Subnet for the VM."
  type        = string
  default     = "192.168.50.16/28"
}

variable "vpn_client_cidrs" {
  description = "Access Server's VPN client subnets, routed back to the VM from the VNet."
  type        = list(string)
  default     = ["172.27.224.0/20", "172.27.240.0/20"]
}

variable "admin_allowed_cidrs" {
  description = "IPv4 CIDR blocks allowed to reach the admin UI on TCP 943, e.g. [\"203.0.113.4/32\"]."
  type        = list(string)

  validation {
    condition     = length(var.admin_allowed_cidrs) > 0 && alltrue([for c in var.admin_allowed_cidrs : can(cidrnetmask(c))])
    error_message = "admin_allowed_cidrs must contain at least one IPv4 CIDR block."
  }
}

variable "vpn_allowed_cidrs" {
  description = "IPv4 CIDR blocks allowed to reach the VPN (UDP 1194, TCP 443)."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.vpn_allowed_cidrs) > 0 && alltrue([for c in var.vpn_allowed_cidrs : can(cidrnetmask(c))])
    error_message = "vpn_allowed_cidrs must contain at least one IPv4 CIDR block."
  }
}

variable "ssh_public_key_file" {
  description = "Path to an OpenSSH public key for admin_username (optional)."
  type        = string
  default     = null
}

variable "ssh_allowed_cidrs" {
  description = "IPv4 CIDR blocks allowed to SSH to the VM. Empty means port 22 is closed."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for c in var.ssh_allowed_cidrs : can(cidrnetmask(c))])
    error_message = "ssh_allowed_cidrs must contain IPv4 CIDR blocks."
  }
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
