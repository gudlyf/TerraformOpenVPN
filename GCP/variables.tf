variable "project" {
  description = "GCP project ID to deploy into."
  type        = string
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

variable "name" {
  description = "Name prefix for all resources."
  type        = string
  default     = "openvpn"
}

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

variable "vpn_allowed_cidrs" {
  description = "IPv4 CIDR blocks allowed to reach the VPN port."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ssh_public_key_file" {
  description = "Path to an OpenSSH public key to install (optional), e.g. \"../certs/ovpn.pub\"."
  type        = string
  default     = null
}

variable "ssh_allowed_cidrs" {
  description = "IPv4 CIDR blocks allowed to SSH to the server. Empty means port 22 is closed."
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
  description = "Directory the .ovpn files are written to. Set to null to skip writing files."
  type        = string
  default     = "../client_configs"
}
