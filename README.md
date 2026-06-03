# Semaphore Test Stand

Terraform-based test stands for [Semaphore UI](https://semaphoreui.com). They
spin up reproducible Semaphore environments for end-to-end testing — from
configuring resources inside a single instance to provisioning full multi-cloud
clusters from scratch.

The repo is split into two independent stands that operate at different layers:

| Stand                | Layer          | What it does                                                                                                                            | Docs                            |
| -------------------- | -------------- | ------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------- |
| [`stand1`](stand1)   | Application    | Configures resources *inside* a running Semaphore instance — projects, keys, repositories, inventories, environments, and templates.  | [stand1/README.md](stand1/README.md) |
| [`stand2`](stand2)   | Infrastructure | Provisions a complete Semaphore UI *cluster* (load balancer + UI nodes + PostgreSQL + Redis + runners) on a cloud provider.            | [stand2/README.md](stand2/README.md) |

The two are independent: `stand1` targets any reachable Semaphore API (typically
a local instance), while `stand2` stands up the cloud infrastructure that
Semaphore itself runs on.

## stand1 — Semaphore resources

Drives a Semaphore instance through the
[`semaphoreui/semaphore`](https://registry.terraform.io/providers/semaphoreui/semaphore/latest/docs)
Terraform provider, declaring the project resources used by the test suite:
projects, SSH/login keys, repositories, inventories, environments (including
variable groups with secrets), and templates that exercise features such as
multiple Ansible vault passwords and env/var secret injection.

```sh
cd stand1
cp terraform.tfvars.example terraform.tfvars   # set api_token
terraform init
terraform apply
```

See [stand1/README.md](stand1/README.md) for obtaining an API token and the full
list of resources.

## stand2 — Cluster infrastructure

Provisions the same Semaphore UI cluster topology — a load balancer fronting
several stateless UI nodes that share one PostgreSQL database and one Redis
instance, plus a pool of runners — on two cloud providers. Each provider has a
`server` stack (the cluster) and a `runner` stack (the task runners). Nodes are
configured at boot through cloud-init templates shared across providers.

| Provider                                         | Stacks                                                       | Docs                                                |
| ------------------------------------------------ | ----------------------------------------------------------- | --------------------------------------------------- |
| DigitalOcean ([`do/`](stand2/do))                | [`server/`](stand2/do/server), [`runner/`](stand2/do/runner)   | [stand2/do/server/README.md](stand2/do/server/README.md) |
| Google Cloud ([`gcp/`](stand2/gcp))              | [`server/`](stand2/gcp/server), [`runner/`](stand2/gcp/runner) | [stand2/gcp/server/README.md](stand2/gcp/server/README.md) |

Both variants terminate TLS at the load balancer with a managed certificate and
use Cloudflare `NS` delegation to a provider-hosted sub-zone for DNS. Shared
configuration (cloud-init templates, the runner service/config, and common
variables) lives in [`stand2/shared/`](stand2/shared).

Each stack is configured through `TF_VAR_*` environment variables sourced from
the shared `.env` files rather than per-stack `.tfvars`:

```sh
cd stand2/gcp/server                                   # or do/server, */runner
gcloud auth application-default login                  # GCP auth (DO uses a token)
set -a; source ../../shared/.env; source ../../shared/.env.gcp; set +a
terraform init
terraform apply
```

See [stand2/shared/README.md](stand2/shared/README.md) for the `.env` layout and
the per-stack READMEs for provider-specific details.

## Repository layout

```
.
├── stand1/                 # Semaphore resources via the semaphoreui provider
└── stand2/                 # Cloud cluster infrastructure
    ├── do/                 # DigitalOcean variant
    │   ├── server/         #   load balancer + UI cluster + Postgres + Redis
    │   └── runner/         #   task runners
    ├── gcp/                # Google Cloud variant
    │   ├── server/
    │   └── runner/
    └── shared/             # cloud-init templates, runner config, shared .env
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- For `stand1`: a reachable Semaphore instance and an API token
- For `stand2`:
  - A cloud account and credentials — DigitalOcean token, or
    [`gcloud`](https://cloud.google.com/sdk/docs/install) with
    `gcloud auth application-default login`
  - A Cloudflare API token (DNS edit + zone read) for the parent domain used in
    certificate delegation

## Secrets

This is a **test stand** — secrets are passed to nodes via cloud-init and stored
in local files. State files, `*.tfvars`, generated tokens, and `shared/.env*`
are git-ignored (see [.gitignore](.gitignore)); only the `*.example` templates
are committed. Copy them and fill in your own values. For production, use a
secrets manager and restrict SSH source IPs in the firewall configuration.
