provider "google" {
  # credentials = "${file("account.json")}"
  project = var.project
  region  = var.region
}

terraform {
  required_version = ">= 0.12"
}
