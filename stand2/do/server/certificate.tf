# Delegated sub-zone, managed in DigitalOcean for Let's Encrypt DNS validation.
resource "digitalocean_domain" "main" {
  name = local.dns_zone
}

# DigitalOcean auto-creates the zone's NS records with TTL 1800, and the
# digitalocean_domain resource cannot manage them — lower the TTL via the API.
resource "terraform_data" "ns_ttl" {
  triggers_replace = [digitalocean_domain.main.id]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    environment = {
      DIGITALOCEAN_TOKEN = var.do_token
      DOMAIN             = digitalocean_domain.main.name
    }

    command = <<-EOT
      set -euo pipefail
      # The API re-validates the whole record on PATCH and the stored NS data
      # lacks the trailing dot it requires, so resend data with the dot added.
      curl -fsS -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
        "https://api.digitalocean.com/v2/domains/$DOMAIN/records?type=NS&per_page=200" \
        | jq -c '.domain_records[] | select(.type == "NS") | {id, data}' \
        | while read -r rec; do
            id=$(jq -r '.id' <<<"$rec")
            data=$(jq -r '.data' <<<"$rec")
            body=$(jq -nc --arg data "$${data%.}." '{data: $data, ttl: 60}')
            curl -fsS -X PATCH \
              -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
              -H "Content-Type: application/json" \
              -d "$body" \
              "https://api.digitalocean.com/v2/domains/$DOMAIN/records/$id" > /dev/null
          done
      echo "Set TTL=60 on NS records of $DOMAIN"
    EOT
  }
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
