# Stand 2 (DigitalOcean) — Semaphore UI cluster

DigitalOcean port of [`stand_hetzner`](../stand_hetzner). Provisions a full
[Semaphore UI](https://semaphoreui.com) deployment with the
[`digitalocean/digitalocean`](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs)
provider.

## Infrastructure

| Resource              | Count | Size          | Notes                                             |
| --------------------- | ----- | ------------- | ------------------------------------------------- |
| Load balancer         | 1     | regional      | HTTPS `:443` → cluster `:3000`, HTTP→HTTPS redirect |
| Semaphore UI cluster  | 3     | `s-1vcpu-2gb` | Behind the LB (see *Zones* below)                 |
| Semaphore runners     | 3     | `s-1vcpu-2gb` | Execute tasks, reach the cluster via the LB       |
| PostgreSQL            | 1     | `s-1vcpu-2gb` | Shared database for the cluster                   |
| Redis                 | 1     | `s-1vcpu-2gb` | Shared cache/session store                        |

All droplets join one VPC (`10.10.10.0/24`). A DigitalOcean Cloud Firewall
allows SSH and `:3000` from anywhere, Postgres/Redis only from the VPC, and all
egress.

### TLS / SSL (subdomain delegation)

The load balancer terminates TLS with a DigitalOcean-managed **Let's Encrypt**
certificate and redirects HTTP→HTTPS. The hostnames are derived from
`local.prefix` + `var.parent_domain`:

- Delegated DO zone: `<prefix>.<parent_domain>` (e.g. `stand2.semaphoreui.dev`)
- LB hostname / cert: `<lb_subdomain>.<prefix>.<parent_domain>`
  (e.g. `lb.stand2.semaphoreui.dev`)

The parent domain (`semaphoreui.dev`) stays hosted on **Cloudflare**. Terraform
manages the whole delegation automatically ([cloudflare.tf](cloudflare.tf)):

1. `digitalocean_domain` creates the `<prefix>.<parent_domain>` sub-zone in
   DigitalOcean.
2. `cloudflare_record` adds three `NS` records on the `<prefix>` label in the
   Cloudflare parent zone, pointing at DigitalOcean's nameservers
   (`ns1/ns2/ns3.digitalocean.com`).
3. Once delegation propagates, DigitalOcean issues the Let's Encrypt cert and
   the LB serves `https://lb.<prefix>.<parent_domain>`.

This needs a `cloudflare_api_token` with **DNS edit** + **zone read** on the
parent domain. Semaphore and the runners are configured with
`web_host = https://<lb_fqdn>` so redirects, cookies and runner registration
work over TLS.

> **Note:** Let's Encrypt validation can't succeed until the NS delegation has
> propagated. On a cold `terraform apply` the certificate may report `pending`;
> re-run `terraform apply` (or `terraform apply -replace=digitalocean_certificate.main`)
> after delegation is live.

### Zones

DigitalOcean does **not** expose availability zones, and both the VPC and the
load balancer are regional. The 3 cluster droplets therefore share a single
region (`var.region`) — the closest functional equivalent to the Hetzner
"different zones" layout. For multi-zone HA, deploy this stack to multiple
regions and front it with DigitalOcean global load balancing / DNS.

## Software provisioning (cloud-init)

Each role boots with a dedicated cloud-init template in [cloud-init/](cloud-init/):

- **postgres** — installs PostgreSQL, discovers its private IP from the
  DigitalOcean metadata service, binds to it, creates the Semaphore
  database/user, and allows `scram-sha-256` access from the VPC.
- **redis** — installs Redis, binds to its private IP, sets a password and AOF.
- **semaphore** — installs Docker, writes `/etc/semaphore/config.yml` pointing
  at Postgres + Redis (private IPs injected by Terraform), runs DB migrations,
  then starts the Semaphore server container. The same `access_key_encryption`
  key is shared across all 3 nodes so they form one cluster.
- **runner** — installs Docker and starts a Semaphore runner that registers
  with the cluster through the load balancer.

## Setup

```sh
cd stand2_do
cp terraform.tfvars.example terraform.tfvars   # fill in token, ssh key, secrets
terraform init
terraform plan
terraform apply
```

Generate the cluster encryption key once and reuse it:

```sh
head -c32 /dev/urandom | base64
```

After apply, open `http://<load_balancer_ip>` and log in with the
`semaphore_admin_*` credentials.

## Differences from the Hetzner stand

- **Zones:** single region (DigitalOcean has no AZ concept) vs. 3 Hetzner
  locations in one network zone.
- **Private IPs:** assigned dynamically by the VPC (referenced via droplet
  attributes / metadata service) rather than statically pre-allocated.
- **Public IPs:** DigitalOcean droplets always get a public IPv4, so there is
  no IPv6-only optimization here.
