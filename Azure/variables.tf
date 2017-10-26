variable "location" {
  default = "Canada East"
}

variable "hostname" {
  default = "openvpn"
}

variable "admin_username" {
  default = "ubuntu"
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
  default = "azure-ovpn"
}

variable "cert_details" {
  default = "../cert_details"
}
