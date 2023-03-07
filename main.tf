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
  target_size        = 2
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

  metadata_startup_script = file("setup-db.sh")

  network_interface {
    subnetwork = google_compute_subnetwork.default.id

    access_config {
      # Ephemeral IP
    }
  }
}
