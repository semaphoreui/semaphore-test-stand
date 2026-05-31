# Public-facing firewall. Hetzner Cloud firewalls filter only the public
# interface, so private-network traffic between servers is unaffected.
resource "hcloud_firewall" "main" {
  name = "${var.prefix}-fw"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # Semaphore UI (also reachable through the LB on :80).
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "3000"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  apply_to {
    label_selector = "stack=${var.prefix}"
  }
}
