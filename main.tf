# Network
resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
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
  target_tags = [ "allow-http" ]
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


# Instance template
resource "google_compute_instance_template" "default" {
  name         = "apache-mig-template"
  machine_type = var.machine_type
  tags         = ["allow-health-check", "internal", "allow-http"]

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.default.id
    access_config {
      # add external ip to fetch packages
    }
  }
  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
  }

  metadata_startup_script = "${file("bootstrap-vm.sh")}"
  # lifecycle {
  #   create_before_destroy = true
  # }
}

resource "google_compute_backend_service" "default" {
  name                    = "backend-service"
  protocol                = "HTTP"
  port_name               = "my-port"
  load_balancing_scheme   = "EXTERNAL"
  timeout_sec             = 10
  health_checks           = [google_compute_health_check.default.id]
  backend {
    group           = google_compute_instance_group_manager.default.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

# reserved IP address
resource "google_compute_global_address" "default" {
  name     = "lb-static-ip"
}

# http proxy
resource "google_compute_target_http_proxy" "default" {
  name     = "lb-target-http-proxy"
  url_map  = google_compute_url_map.default.id
}


# forwarding rule
resource "google_compute_global_forwarding_rule" "default" {
  name                  = "lb-forwarding-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_http_proxy.default.id
  ip_address            = google_compute_global_address.default.id
}


# url map
resource "google_compute_url_map" "default" {
  name            = "lb-url-map"
  default_service = google_compute_backend_service.default.id
}

# health check
resource "google_compute_health_check" "default" {
  name     = "apache-server-hc"
  http_health_check {
    port_specification = "USE_SERVING_PORT"
  }
}

# MIG
resource "google_compute_instance_group_manager" "default" {
  name     = "apache-server-mig"
  zone     = var.zone
  named_port {
    name = "my-port"
    port = 80
  }
  version {
    instance_template = google_compute_instance_template.default.id
    name              = "primary"
  }
  base_instance_name = "apache-server-vm"
  target_size        = 3
}

# DB instance
resource "google_compute_instance" "db" {
  name         = "db-server-vm"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["internal"]
  allow_stopping_for_update = "${var.allow_stopping_for_update}"

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }

  metadata_startup_script = <<EOF
!/bin/bash
sudo yum install -y mariadb-server
sudo systemctl enable mariadb
sudo systemctl start mariadb
mysql -u root -e "CREATE DATABASE mydb"
mysql -u root -e "CREATE USER 'myuser'@'localhost' IDENTIFIED BY 'mypassword'"
mysql -u root -e "GRANT ALL PRIVILEGES ON mydb.* TO 'myuser'@'localhost'"
EOF



  network_interface {
    subnetwork = google_compute_subnetwork.default.id

    access_config {
      # Ephemeral IP
    }
  }
}


# Webserver instance 
# resource "google_compute_instance" "default" {
#   name         = "apache-server-vm"
#   machine_type = var.machine_type
#   zone         = var.zone
#   tags         = ["internal","allow-http"]
#   allow_stopping_for_update = "${var.allow_stopping_for_update}"

#   boot_disk {
#     initialize_params {
#       image = "debian-cloud/debian-11"
#     }
#   }

#   metadata_startup_script = "${file("bootstrap-vm.sh")}"

#   network_interface {
#     subnetwork = google_compute_subnetwork.default.id

#     access_config {
#       # Ephemeral IP
#     }
#   }
# }

// A variable for extracting the external IP address of the VM
# output "Web-server-URL" {
#   value = join("", ["http://", google_compute_instance.default.network_interface.0.access_config.0.nat_ip, ":80"])
# }





