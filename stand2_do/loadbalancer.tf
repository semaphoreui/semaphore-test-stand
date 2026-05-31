resource "digitalocean_loadbalancer" "main" {
  name     = "${var.prefix}-lb"
  region   = var.region
  vpc_uuid = digitalocean_vpc.main.id

  # Route the 3 Semaphore UI droplets behind the LB via their shared tag.
  droplet_tag = digitalocean_tag.ui.name

  # Terminate TLS at the LB; forward plain HTTP to Semaphore on :3000.
  redirect_http_to_https = true

  forwarding_rule {
    entry_protocol   = "https"
    entry_port       = 443
    target_protocol  = "http"
    target_port      = 3000
    certificate_name = digitalocean_certificate.main.name
  }

  healthcheck {
    protocol                 = "http"
    port                     = 3000
    path                     = "/api/ping"
    check_interval_seconds   = 10
    response_timeout_seconds = 5
    healthy_threshold        = 3
    unhealthy_threshold      = 3
  }

  depends_on = [digitalocean_droplet.cluster]
}
