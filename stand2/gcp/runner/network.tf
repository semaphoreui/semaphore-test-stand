# Reuse the VPC and subnet created by the server stack (matched by prefix).
data "google_compute_network" "main" {
  name = "${var.prefix}-vpc"
}

data "google_compute_subnetwork" "main" {
  name   = "${var.prefix}-subnet"
  region = var.region
}
