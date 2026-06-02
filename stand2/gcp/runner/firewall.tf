# Runners need no inbound service ports — only SSH (admin) and ICMP. Egress is
# allowed by default, which covers apt, the release download, and reaching the
# cluster through the load balancer.
resource "google_compute_firewall" "runner_ssh" {
  name          = "${var.prefix}-runner-allow-ssh"
  network       = data.google_compute_network.main.id
  target_tags   = [local.tag_runner]
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "runner_icmp" {
  name          = "${var.prefix}-runner-allow-icmp"
  network       = data.google_compute_network.main.id
  target_tags   = [local.tag_runner]
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "icmp"
  }
}
