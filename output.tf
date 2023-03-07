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


