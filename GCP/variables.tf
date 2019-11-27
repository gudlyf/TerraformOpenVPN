variable "region" {
  default = "northamerica-northeast1"
}

variable "zone" {
  default = "northamerica-northeast1-a"
}

variable "project" {
  default = "terraform-vpn"
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
  default = "gcp-ovpn-client"
}

variable "cert_details" {
  default = "../cert_details"
}

