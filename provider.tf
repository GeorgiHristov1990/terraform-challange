terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

provider "google" {
  credentials = file("gcp/key.json")

  project = "endava-challange-379513"
  region  = var.region
  zone    = var.zone
}
