# Delegated sub-zone, managed in DigitalOcean for Let's Encrypt DNS validation.
resource "digitalocean_domain" "main" {
  name = local.dns_zone
}

# DO-managed Let's Encrypt certificate, auto-renewed.
resource "digitalocean_certificate" "main" {
  name    = "${local.prefix}-cert"
  type    = "lets_encrypt"
  domains = ["lb.${local.dns_zone}"]

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
  name   = "lb"
  value  = digitalocean_loadbalancer.main.ip
  ttl    = 60
}
