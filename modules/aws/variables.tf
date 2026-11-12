################################################################################
# Infrastructure
################################################################################

variable "name" {
  description = "Name prefix for all resources."
  type        = string
  default     = "openvpn"

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-]{0,31}$", var.name))
    error_message = "name must be 1-32 characters of letters, digits or '-' and start with a letter or digit."
  }
}

variable "instance_type" {
  description = "EC2 instance type. Graviton (arm64) and x86_64 types both work; the matching Ubuntu AMI is picked automatically."
  type        = string
  default     = "t4g.micro"
}

variable "ami_id" {
  description = "Override the AMI. Defaults to the latest Canonical Ubuntu 24.04 LTS image for the instance type's architecture."
  type        = string
  default     = null
}

variable "root_volume_size" {
  description = "Root volume size in GiB."
  type        = number
  default     = 8
}

variable "vpc_cidr" {
  description = "CIDR block for the dedicated VPC. Must not overlap vpn_cidr."
  type        = string
  default     = "10.10.0.0/24"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be an IPv4 CIDR block."
  }
}

variable "availability_zone" {
  description = "Availability zone to launch in. Defaults to the first zone that offers instance_type."
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
  description = "OpenSSH public key for the \"ubuntu\" user. SSH is optional; leave null to launch without a key pair."
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
  default     = "aws-"
}
