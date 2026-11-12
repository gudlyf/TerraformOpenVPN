terraform {
  required_version = ">= 1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 8.0, < 9.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5, < 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6, < 4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0, < 5.0"
    }
  }
}
