provider "aws" {
  profile = var.profile
  region  = var.region
}

terraform {
  required_version = ">= 0.12"
}
