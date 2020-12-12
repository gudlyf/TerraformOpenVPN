variable "location" {
  default = "westus2"
}

variable "hostname" {
  default = "openvpn"
}

variable "admin_username" {
  default = "ubuntu"
}

# Variable to restrict SSH access by NSG ACL to internet IP of client running tf
variable "restrict_ssh" {
  description = "If set to true, restrict SSH by NSG ACL"
  type        = bool
  default     = true
}

# Variable to restrict VPN access by NSG ACL to internet IP of client running tf
variable "restrict_vpn" {
  description = "If set to true, restrict vpn by NSG ACL"
  type        = bool
  default     = true
}

variable "private_key_file" {
  default = "../certs/ovpn"
}

variable "public_key_file" {
  default = "../certs/ovpn.pub"
}

variable "client_config_path" {
  default = "../client_configs"
}

variable "client_config_name" {
  default = "azure-ovpn-client"
}

variable "cert_details" {
  default = "../cert_details"
}

