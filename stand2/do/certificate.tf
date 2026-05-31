locals {
  # Sub-zone delegated to DigitalOcean (NS records added in the parent's DNS).
  dns_zone = "${var.prefix}.${var.parent_domain}"
  # Public HTTPS hostname for the load balancer.
  lb_fqdn = "${var.lb_subdomain}.${local.dns_zone}"
}

# Delegated sub-zone, managed in DigitalOcean for Let's Encrypt DNS validation.
resource "digitalocean_domain" "main" {
  name = local.dns_zone
}

# DO-managed Let's Encrypt certificate, auto-renewed.
resource "digitalocean_certificate" "main" {
  name    = "${var.prefix}-cert"
  type    = "lets_encrypt"
  domains = [local.lb_fqdn]

  # Delegation must be in place before DigitalOcean can validate via DNS.
  depends_on = [cloudflare_record.delegation]

  lifecycle {
    create_before_destroy = true
  }
}

# Point the load balancer hostname at the load balancer IP.
resource "digitalocean_record" "lb" {
  domain = digitalocean_domain.main.name
  type   = "A"
  name   = var.lb_subdomain
  value  = digitalocean_loadbalancer.main.ip
  ttl    = 300
}
