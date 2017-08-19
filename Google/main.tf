provider "google" {
  credentials = "${file("account.json")}"
  project     = "terraform-vpn"
  region      = "${var.region}"
}
