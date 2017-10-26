variable "region" {
  default = "us-east1"
}

variable "zone" {
  default = "us-east1-b"
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
  default = "google-ovpn"
}

variable "cert_details" {
  default = "../cert_details"
}
