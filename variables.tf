variable "profile" {}

variable "region" {
  default = "ca-central-1"
}

variable "private_key_file" {
  default = "./ovpn"
}

variable "public_key_file" {
  default = "./ovpn.pub"
}
