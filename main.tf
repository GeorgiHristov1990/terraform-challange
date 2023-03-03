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
  region  = "europe-west8"
  zone    = "europe-west8-a"
}

resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}