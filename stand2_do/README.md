# Stand 2 (DigitalOcean) — Semaphore UI cluster

DigitalOcean port of [`stand_hetzner`](../stand_hetzner). Provisions a full
[Semaphore UI](https://semaphoreui.com) deployment with the
[`digitalocean/digitalocean`](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs)
provider.

## Infrastructure

| Resource              | Count | Size          | Notes                                             |
| --------------------- | ----- | ------------- | ------------------------------------------------- |
| Load balancer         | 1     | regional      | Public `:80` → cluster `:3000`, HTTP health check |
| Semaphore UI cluster  | 3     | `s-1vcpu-2gb` | Behind the LB (see *Zones* below)                 |
| Semaphore runners     | 3     | `s-1vcpu-2gb` | Execute tasks, reach the cluster via the LB       |
| PostgreSQL            | 1     | `s-1vcpu-2gb` | Shared database for the cluster                   |
| Redis                 | 1     | `s-1vcpu-2gb` | Shared cache/session store                        |

All droplets join one VPC (`10.10.10.0/24`). A DigitalOcean Cloud Firewall
allows SSH and `:3000` from anywhere, Postgres/Redis only from the VPC, and all
egress.

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
- **semaphore** — installs Docker, writes `/etc/semaphore/config.json` pointing
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

### Runner registration

Set `runner_registration_token` to have runners self-register on first boot.
Without it, runners install but wait — register them manually afterwards (see
the [Semaphore runner docs](https://docs.semaphoreui.com/administration-guide/runners/)).

## Differences from the Hetzner stand

- **Zones:** single region (DigitalOcean has no AZ concept) vs. 3 Hetzner
  locations in one network zone.
- **Private IPs:** assigned dynamically by the VPC (referenced via droplet
  attributes / metadata service) rather than statically pre-allocated.
- **Public IPs:** DigitalOcean droplets always get a public IPv4, so there is
  no IPv6-only optimization here.
