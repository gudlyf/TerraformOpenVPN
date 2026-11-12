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

variable "region" {
  description = "GCP region."
  type        = string
  default     = "northamerica-northeast1"
}

variable "zone" {
  description = "GCP zone. Defaults to the first available zone in region."
  type        = string
  default     = null
}

variable "machine_type" {
  description = "Compute Engine machine type."
  type        = string
  default     = "e2-micro"
}

variable "image" {
  description = "Boot image. Use the arm64 family (ubuntu-os-cloud/ubuntu-2404-lts-arm64) with Arm machine types such as t2a or c4a."
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
}

variable "boot_disk_size" {
  description = "Boot disk size in GB."
  type        = number
  default     = 10
}

variable "subnet_cidr" {
  description = "CIDR block for the dedicated subnetwork. Must not overlap vpn_cidr."
  type        = string
  default     = "10.10.0.0/24"

  validation {
    condition     = can(cidrnetmask(var.subnet_cidr))
    error_message = "subnet_cidr must be an IPv4 CIDR block."
  }
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

variable "ssh_user" {
  description = "Username the SSH key is installed for."
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "OpenSSH public key for ssh_user. SSH is optional; leave null to skip."
  type        = string
  default     = null
}

variable "ssh_allowed_cidrs" {
  description = "IPv4 CIDR blocks allowed to SSH to the instance. Empty (the default) means port 22 is closed."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for c in var.ssh_allowed_cidrs : can(cidrnetmask(c))])
    error_message = "ssh_allowed_cidrs must contain IPv4 CIDR blocks, e.g. 203.0.113.4/32."
  }
}

variable "labels" {
  description = "Labels applied to resources that support them."
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
  default     = "gcp-"
}
