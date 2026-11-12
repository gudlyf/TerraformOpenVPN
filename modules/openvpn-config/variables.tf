variable "name" {
  description = "Name used as a prefix for certificate common names."
  type        = string
  default     = "openvpn"

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9_-]{0,47}$", var.name))
    error_message = "name must be 1-48 characters of letters, digits, '-' or '_' and start with a letter or digit."
  }
}

variable "server_address" {
  description = "Public IP address or DNS name that clients connect to. Written into each client profile."
  type        = string

  validation {
    condition     = length(trimspace(var.server_address)) > 0
    error_message = "server_address must not be empty."
  }
}

variable "clients" {
  description = "Client names to issue certificates and .ovpn profiles for. Removing a name revokes that client's access."
  type        = set(string)
  default     = ["client"]

  validation {
    condition     = length(var.clients) > 0
    error_message = "At least one client is required."
  }

  validation {
    condition     = alltrue([for c in var.clients : can(regex("^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$", c))])
    error_message = "Client names must be 1-64 characters of letters, digits, '-' or '_' and start with a letter or digit."
  }
}

variable "port" {
  description = "Port OpenVPN listens on."
  type        = number
  default     = 1194

  validation {
    condition     = var.port >= 1 && var.port <= 65535 && floor(var.port) == var.port
    error_message = "port must be an integer between 1 and 65535."
  }
}

variable "protocol" {
  description = "Transport protocol: \"udp\" (recommended) or \"tcp\"."
  type        = string
  default     = "udp"

  validation {
    condition     = contains(["udp", "tcp"], var.protocol)
    error_message = "protocol must be \"udp\" or \"tcp\"."
  }
}

variable "vpn_cidr" {
  description = "IPv4 network handed out to VPN clients. Must not overlap the cloud network or your local networks."
  type        = string
  default     = "10.8.0.0/24"

  validation {
    condition     = can(cidrnetmask(var.vpn_cidr)) && tonumber(split("/", var.vpn_cidr)[1]) <= 29
    error_message = "vpn_cidr must be an IPv4 CIDR block of /29 or larger, e.g. 10.8.0.0/24."
  }

  validation {
    condition     = can(cidrhost(var.vpn_cidr, 0)) && cidrhost(var.vpn_cidr, 0) == split("/", var.vpn_cidr)[0]
    error_message = "vpn_cidr must be a network address (e.g. 10.8.0.0/24, not 10.8.0.5/24)."
  }
}

variable "full_tunnel" {
  description = "Route all client traffic through the VPN. Set to false for split tunnelling with pushed_routes."
  type        = bool
  default     = true
}

variable "pushed_routes" {
  description = "Extra IPv4 CIDR routes pushed to clients (mainly useful when full_tunnel is false)."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for r in var.pushed_routes : can(cidrnetmask(r))])
    error_message = "Every pushed_routes entry must be an IPv4 CIDR block."
  }
}

variable "dns_servers" {
  description = "DNS servers pushed to clients."
  type        = list(string)
  default     = ["1.1.1.1", "9.9.9.9"]

  validation {
    condition     = alltrue([for d in var.dns_servers : can(cidrhost("${d}/32", 0))])
    error_message = "dns_servers must be IPv4 addresses."
  }
}

variable "cert_subject" {
  description = "Subject fields for the generated certificates (replaces the old cert_details file)."
  type = object({
    organization        = optional(string, "TerraformOpenVPN")
    organizational_unit = optional(string)
    country             = optional(string)
    province            = optional(string)
    locality            = optional(string)
  })
  default = {}

  validation {
    condition     = var.cert_subject.country == null || can(regex("^[A-Z]{2}$", var.cert_subject.country))
    error_message = "cert_subject.country must be a two-letter ISO country code, e.g. \"US\"."
  }
}

variable "ca_validity_hours" {
  description = "Validity period of the CA certificate, in hours. Default is 10 years."
  type        = number
  default     = 87600
}

variable "cert_validity_hours" {
  description = "Validity period of server and client certificates, in hours. Default is 5 years."
  type        = number
  default     = 43800

  validation {
    condition     = var.cert_validity_hours >= 24
    error_message = "cert_validity_hours must be at least 24."
  }
}

variable "client_config_dir" {
  description = "Directory to write <prefix><client>.ovpn files to. Set to null to skip writing files (profiles remain available via the client_configs output)."
  type        = string
  default     = null
}

variable "client_config_prefix" {
  description = "Prefix for generated .ovpn file names, e.g. \"aws-\" gives aws-client.ovpn."
  type        = string
  default     = ""
}

variable "upgrade_packages" {
  description = "Run a full package upgrade on first boot."
  type        = bool
  default     = true
}

variable "reboot_if_required" {
  description = "Reboot at the end of first boot if package upgrades require it."
  type        = bool
  default     = true
}

variable "enable_fail2ban" {
  description = "Install fail2ban with an sshd jail. Useful only when SSH is reachable."
  type        = bool
  default     = false
}
