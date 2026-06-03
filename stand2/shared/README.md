# Shared variables

Settings common to multiple stacks live here so they're defined once. They are
**not** auto-loaded (no symlinks) — pass them explicitly with `-var-file` on each
`plan`/`apply`. Each stack's own `terraform.tfvars` still auto-loads its
stack-specific values (`prefix`, `web_root`, `runners`, ...).

| file            | contents                                                        | used by                |
|-----------------|-----------------------------------------------------------------|------------------------|
| `common.tfvars` | `ssh_public_key`, `semaphore_version`                           | all 4 stacks           |
| `server.tfvars` | `cloudflare_api_token`, `parent_domain`, DB/Redis/admin secrets | do/server, gcp/server  |
| `do.tfvars`     | `do_token`                                                      | do/server, do/runner   |
| `gcp.tfvars`    | `gcp_project`                                                   | gcp/server, gcp/runner |

Real files hold secrets and are git-ignored; copy the `*.tfvars.example` versions
and fill them in.

## Apply commands (run from inside each stack dir)

```sh

cd stand2/do/runner

set -a; source ../../shared/.env; source ../../shared/.env.do; set +a

terraform apply
```
