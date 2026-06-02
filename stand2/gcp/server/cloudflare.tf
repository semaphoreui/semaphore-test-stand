# Delegates the '<prefix>.<parent_domain>' sub-zone from Cloudflare to Google
# Cloud DNS by creating NS records in the Cloudflare-hosted parent zone. The
# parent zone itself stays on Cloudflare. The delegated nameservers come from
# the Google-managed zone (certificate.tf).

data "cloudflare_zone" "parent" {
  name = var.parent_domain
}

resource "cloudflare_record" "delegation" {
  for_each = toset(google_dns_managed_zone.main.name_servers)

  zone_id = data.cloudflare_zone.parent.id
  name    = local.dns_zone # e.g. stand2.semaphoreui.dev
  type    = "NS"
  content = each.value
  ttl     = 3600
  # NS records cannot be proxied through Cloudflare.
}
