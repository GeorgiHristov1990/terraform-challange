# backend
resource "google_compute_backend_service" "default" {
  name                  = "backend-service"
  protocol              = "HTTP"
  port_name             = "my-port"
  load_balancing_scheme = "EXTERNAL"
  timeout_sec           = 10
  health_checks = [google_compute_health_check.default.id]
  backend {
    group           = google_compute_instance_group_manager.default.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
#   backend {
#     group = google_compute_instance_group_manager.secondary_failover_group.instance_group
#   }
  depends_on = [
    google_compute_instance_template.default
  ]
}

# reserved IP address
resource "google_compute_global_address" "default" {
  name = "lb-static-ip"
}

# http proxy
resource "google_compute_target_http_proxy" "default" {
  name    = "lb-target-http-proxy"
  url_map = google_compute_url_map.default.id
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
