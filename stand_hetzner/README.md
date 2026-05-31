# Stand Hetzner — Semaphore UI cluster on Hetzner Cloud

Provisions a full [Semaphore UI](https://semaphoreui.com) deployment on
[Hetzner Cloud](https://www.hetzner.com/cloud) with the
[`hetznercloud/hcloud`](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs)
provider.

## Infrastructure

| Resource              | Count | Type        | Notes                                              |
| --------------------- | ----- | ----------- | -------------------------------------------------- |
| Load balancer         | 1     | `lb11`      | Public `:80` → cluster `:3000`, HTTP health check  |
| Semaphore UI cluster  | 3     | `cx22`      | One per zone (`fsn1`, `nbg1`, `hel1`)              |
| Semaphore runners     | 3     | `cx22`      | Execute tasks, reach the cluster via the LB        |
| PostgreSQL            | 1     | `cx22`      | Shared database for the cluster                    |
| Redis                 | 1     | `cx22`      | Shared cache/session store                         |

All servers join a private network (`10.0.0.0/16`, subnet `10.0.1.0/24`) with
static internal IPs so cloud-init can wire services together at boot. Public
firewall allows SSH, `:3000`, and ICMP; private traffic is unfiltered.

## Software provisioning (cloud-init)

Each role boots with a dedicated cloud-init template in [cloud-init/](cloud-init/):

- **postgres** — installs PostgreSQL, binds to its private IP, creates the
  Semaphore database/user, and allows `scram-sha-256` access from the subnet.
- **redis** — installs Redis, binds to its private IP, sets a password and AOF.
- **semaphore** — installs Docker, writes `/etc/semaphore/config.json` pointing
  at Postgres + Redis, runs DB migrations, then starts the Semaphore server
  container. The same `access_key_encryption` key is shared across all 3 nodes
  so they form one cluster against the shared database.
- **runner** — installs Docker and starts a Semaphore runner that registers
  with the cluster through the load balancer.

## Setup

```sh
cd stand_hetzner
cp terraform.tfvars.example terraform.tfvars   # fill in token, ssh key, secrets
terraform init
terraform plan
terraform apply
```

Generate the cluster encryption key once and reuse it:

```sh
head -c32 /dev/urandom | base64
```

After apply, open `http://<load_balancer_public_ip>` and log in with the
`semaphore_admin_*` credentials.

### Runner registration

Set `runner_registration_token` to have runners self-register on first boot.
Without it, runners install but wait — register them manually afterwards (see
the [Semaphore runner docs](https://docs.semaphoreui.com/administration-guide/runners/)).

## Notes

- "Different zones" is implemented by placing the 3 cluster servers in 3
  Hetzner locations within the `eu-central` network zone, so they still share
  one private network.
- Secrets are passed via cloud-init `user_data`; for production use a secrets
  manager and restrict SSH source IPs in [firewall.tf](firewall.tf).
