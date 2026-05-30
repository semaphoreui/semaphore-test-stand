# Variable Group With Secrets — test scenario

Verifies that Ansible (and Semaphore) inject **variable group** data correctly:

- plain **environment** entries (`AWS_DEFAULT_REGION`)
- plain **extra variables** (`cloud_provider_hint`)
- **secret** entries typed as `env` (exported to the process environment)
- **secret** entries typed as `var` (passed as Ansible extra vars)

Fake cloud credential names are used (AWS / Azure / GCP style); values are
obviously non-production placeholders.

## Layout

```
tests/var-group-with-secrets/
├── run-test.sh        # Bash equivalent of test.yml (no Ansible)
├── test.yml           # entrypoint playbook (localhost)
├── inventory.ini      # local-only inventory
└── roles/
    ├── aws/           # asserts env-type secrets + plain env var
    ├── azure/         # asserts var-type secrets (extra vars)
    └── gcp/           # asserts var-type secrets + plain extra var
```

## Secret and variable map

| Name | Semaphore type | Kind | Expected value |
|------|----------------|------|----------------|
| `AWS_ACCESS_KEY_ID` | secret | `env` | `AKIAFAKE00000000001` |
| `AWS_SECRET_ACCESS_KEY` | secret | `env` | `fake-aws-secret-access-key-32chars!!` |
| `AWS_DEFAULT_REGION` | environment | plain | `us-east-1` |
| `ARM_CLIENT_ID` | secret | `var` | `00000000-0000-0000-0000-00000000azure` |
| `ARM_CLIENT_SECRET` | secret | `var` | `fake-azure-client-secret-value` |
| `ARM_TENANT_ID` | secret | `var` | `11111111-1111-1111-1111-111111111111` |
| `GCP_PROJECT_ID` | secret | `var` | `fake-gcp-demo-project` |
| `GCP_SERVICE_ACCOUNT_EMAIL` | secret | `var` | `fake-sa@fake-gcp-demo-project.iam.gserviceaccount.com` |
| `cloud_provider_hint` | variable | plain | `fake-multi-cloud-demo` |

## Run locally

### Bash script (recommended)

`run-test.sh` mirrors the three Ansible roles (`aws`, `azure`, `gcp`) in pure
Bash: show values, assert fingerprints, print success/fail messages. Locally it
injects fake secrets when the environment is empty; under Semaphore it uses the
variable group already attached to the template.

```sh
cd tests/var-group-with-secrets
./run-test.sh
```

### Ansible playbook (optional)

```sh
cd tests/var-group-with-secrets

export AWS_ACCESS_KEY_ID="AKIAFAKE00000000001"
export AWS_SECRET_ACCESS_KEY="fake-aws-secret-access-key-32chars!!"
export AWS_DEFAULT_REGION="us-east-1"

ansible-playbook -i inventory.ini test.yml \
  -e cloud_provider_hint=fake-multi-cloud-demo \
  -e ARM_CLIENT_ID=00000000-0000-0000-0000-00000000azure \
  -e ARM_CLIENT_SECRET=fake-azure-client-secret-value \
  -e ARM_TENANT_ID=11111111-1111-1111-1111-111111111111 \
  -e GCP_PROJECT_ID=fake-gcp-demo-project \
  -e GCP_SERVICE_ACCOUNT_EMAIL=fake-sa@fake-gcp-demo-project.iam.gserviceaccount.com
```

Expected outcome: every `OK:` line and `=> … OK` role message; exit code `0`.
For Ansible, all three roles print their `success_msg` and the play ends with
`failed=0`.

## Wire it into Semaphore

Terraform in `stands/stand1/environment_cloud_secrets.tf` defines:

1. **Variable group** `cloud-secrets` with the table above.
2. **Task templates** (both use variable group `cloud-secrets`):
   - `var-group-with-secrets` — app **ansible**, playbook `tests/var-group-with-secrets/test.yml`
   - `var-group-with-secrets-bash` — app **bash**, script `tests/var-group-with-secrets/run-test.sh`

Reuses the same repository, inventory (`localhost`), and `none` key as the
other stand-1 templates:

```sh
cd stands/stand1
terraform apply
```

Then run either template from the Semaphore UI.

## Negative checks (optional)

- Omit `AWS_ACCESS_KEY_ID` from the environment when running locally → `aws`
  role assert fails.
- Pass a wrong `ARM_CLIENT_SECRET` extra var → `azure` role assert fails.
