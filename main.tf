resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}

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


resource "google_compute_subnetwork" "default" {
  name          = "my-custom-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}


resource "google_compute_instance" "default" {
  name         = "apache-server-vm"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["internal"]
  allow_stopping_for_update = "${var.allow_stopping_for_update}"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  metadata_startup_script = <<EOF
#!/bin/bash
sudo apt-get update
sudo apt-get install -y apache2
sudo systemctl start apache2
sudo echo "<h1>This is my webserver</h1>" > /var/www/html/index.html
EOF

  network_interface {
    subnetwork = google_compute_subnetwork.default.id

    access_config {
      # Ephemeral IP
    }
  }
}

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


// A variable for extracting the external IP address of the VM
output "Web-server-URL" {
  value = join("", ["http://", google_compute_instance.default.network_interface.0.access_config.0.nat_ip, ":80"])
}
