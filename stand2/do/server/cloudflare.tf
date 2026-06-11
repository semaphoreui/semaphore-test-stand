# Delegates the '<prefix>.<parent_domain>' sub-zone from Cloudflare to
# DigitalOcean by creating NS records in the Cloudflare-hosted parent zone.
# The parent zone itself stays on Cloudflare.

locals {
  # DigitalOcean's anycast nameservers (fixed for all DO-managed domains).
  digitalocean_nameservers = [
    "ns1.digitalocean.com",
    "ns2.digitalocean.com",
    "ns3.digitalocean.com",
  ]
}

data "cloudflare_zone" "parent" {
  name = var.parent_domain
}

resource "cloudflare_record" "delegation" {
  for_each = toset(local.digitalocean_nameservers)

  zone_id = data.cloudflare_zone.parent.id
  name    = local.dns_zone
  type    = "NS"
  content = each.value
  ttl     = 60
  # NS records cannot be proxied through Cloudflare.

  # Ensure the DO zone exists before pointing nameservers at it.
  depends_on = [digitalocean_domain.main]
}
