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
  metadata = {
    "google-logging-enabled" = "true"
  }

  metadata_startup_script = file("scripts/bootstrap-vm.sh")
}

# MIG for webserver
resource "google_compute_instance_group_manager" "default" {
  name               = "apache-server-mig"
  base_instance_name = "apache-server-vm"
  target_size        = 2
  zone               = var.zone

  named_port {
    name = "my-port"
    port = 80
  }
  version {
    instance_template = google_compute_instance_template.default.id
    name              = "primary"
  }
  auto_healing_policies {
    health_check = google_compute_health_check.default.id
    initial_delay_sec = 120
  }
}

# health check
resource "google_compute_health_check" "default" {
  name = "apache-server-hc"

  check_interval_sec  = 10
  timeout_sec         = 5
  unhealthy_threshold = 3
  healthy_threshold   = 2

  http_health_check {
    # port_specification = "USE_SERVING_PORT"
    port = 80
  }
}

# DB instance
resource "google_compute_instance" "db" {
  name                      = "db-server-vm"
  machine_type              = var.machine_type
  zone                      = var.zone
  tags                      = ["internal"]
  allow_stopping_for_update = var.allow_stopping_for_update

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }

  metadata_startup_script = file("scripts/setup-db.sh")

  network_interface {
    subnetwork = google_compute_subnetwork.default.id

    access_config {
      # Ephemeral IP
    }
  }
}
