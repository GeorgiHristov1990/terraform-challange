# Network
resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
  name          = "my-custom-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

# Firewall Rules
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow-http" {
  name    = "allow-http"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-http"]
}

resource "google_compute_firewall" "internal" {
  name          = "internal-communication"
  network       = google_compute_network.vpc_network.self_link
  direction     = "INGRESS"
  source_ranges = [google_compute_subnetwork.default.ip_cidr_range]
  target_tags   = ["internal"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
}

# allow access from health check ranges
resource "google_compute_firewall" "default" {
  name          = "allow-hc"
  direction     = "INGRESS"
  network       = google_compute_network.vpc_network.id
#   source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  source_ranges = ["0.0.0.0/0"]
  allow {
    protocol = "tcp"
  }
  target_tags = ["allow-health-check"]
}