# Stand 2 — Semaphore UI cluster test stand

A Terraform-provisioned [Semaphore UI](https://semaphoreui.com) cluster used for
testing clustered deployments end-to-end: multiple UI nodes behind a load
balancer, sharing one PostgreSQL database and one Redis instance, with a pool of
runners that execute tasks.

The same topology is provided for two cloud providers — pick one:

| Variant       | Provider      | Directory   | Docs                          |
| ------------- | ------------- | ----------- | ----------------------------- |
| DigitalOcean  | `digitalocean`| [`do/`](do) | [do/README.md](do/README.md)  |
| Hetzner Cloud | `hcloud`      | [`hz/`](hz) | [hz/README.md](hz/README.md)  |

## Topology

Both variants provision the same logical layout:

| Role                 | Count | Notes                                            |
| -------------------- | ----- | ------------------------------------------------ |
| Load balancer        | 1     | Public entrypoint → cluster `:3000`              |
| Semaphore UI cluster | 3     | Stateless nodes sharing one DB + Redis           |
| Semaphore runners    | 3     | Execute tasks, reach the cluster via the LB      |
| PostgreSQL           | 1     | Shared database for the cluster                  |
| Redis                | 1     | Shared cache / session store                     |

All nodes join a private network so cloud-init can wire services together at
boot. The 3 UI nodes share the same `access_key_encryption` key, which is what
lets them act as one cluster against the shared database.

## Software provisioning (cloud-init)

Each role boots from a dedicated cloud-init template under `<variant>/cloud-init/`:

- **postgres** — installs PostgreSQL, binds to its private IP, creates the
  Semaphore database/user, allows access from the private network.
- **redis** — installs Redis, binds to its private IP, sets a password and AOF.
- **semaphore** — runs the Semaphore server (Docker or systemd variant),
  configured to point at Postgres + Redis, runs DB migrations on boot.
- **runner** — runs a Semaphore runner that registers with the cluster through
  the load balancer.

## Quick start

```sh
cd do        # or: cd hz
cp terraform.tfvars.example terraform.tfvars   # fill in token, ssh key, secrets
terraform init
terraform plan
terraform apply
```

Generate the shared cluster encryption key once and reuse it across nodes:

```sh
head -c32 /dev/urandom | base64
```

After apply, open the load balancer address from the Terraform outputs and log
in with the `semaphore_admin_*` credentials.

## Differences between variants

- **DigitalOcean (`do/`)** — single region (DigitalOcean has no availability
  zones); LB terminates TLS with a managed Let's Encrypt certificate via
  subdomain delegation (DO sub-zone + Cloudflare `NS` records). See
  [do/README.md](do/README.md).
- **Hetzner (`hz/`)** — 3 cluster nodes spread across 3 locations in the
  `eu-central` network zone; Postgres and Redis are IPv6-only to stay within the
  IPv4 quota. See [hz/README.md](hz/README.md).

> Secrets are passed via cloud-init `user_data`. This is a test stand — for
> production use a secrets manager and restrict SSH source IPs in the firewall
> config.
