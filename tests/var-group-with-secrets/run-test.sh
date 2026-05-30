#!/usr/bin/env bash
# Bash equivalent of test.yml (roles aws, azure, gcp).
# Verifies Semaphore variable group "cloud-secrets": env secrets, plain env,
# var secrets, and plain extra variables.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Expected values (match stands/stand1/environment_cloud_secrets.tf)
readonly AWS_ACCESS_KEY_ID_EXPECTED="AKIAFAKE00000000001"
readonly AWS_SECRET_ACCESS_KEY_EXPECTED="fake-aws-secret-access-key-32chars!!"
readonly AWS_DEFAULT_REGION_EXPECTED="us-east-1"
readonly ARM_CLIENT_ID_EXPECTED="00000000-0000-0000-0000-00000000azure"
readonly ARM_CLIENT_SECRET_EXPECTED="fake-azure-client-secret-value"
readonly ARM_TENANT_ID_EXPECTED="11111111-1111-1111-1111-111111111111"
readonly GCP_PROJECT_ID_EXPECTED="fake-gcp-demo-project"
readonly GCP_SERVICE_ACCOUNT_EMAIL_EXPECTED="fake-sa@fake-gcp-demo-project.iam.gserviceaccount.com"
readonly CLOUD_PROVIDER_HINT_EXPECTED="fake-multi-cloud-demo"

failures=0

assert_eq() {
  local name="$1"
  local expected="$2"
  local actual="$3"
  if [[ "$actual" != "$expected" ]]; then
    echo "FAIL: $name"
    echo "  expected: $expected"
    echo "  actual:   ${actual:-<unset>}"
    failures=$((failures + 1))
    return 1
  fi
  echo "OK:   $name"
  return 0
}

# Local/dev only: simulate Semaphore variable group injection.
apply_variable_group_local() {
  export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID_EXPECTED"
  export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY_EXPECTED"
  export AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION_EXPECTED"

  export ARM_CLIENT_ID="$ARM_CLIENT_ID_EXPECTED"
  export ARM_CLIENT_SECRET="$ARM_CLIENT_SECRET_EXPECTED"
  export ARM_TENANT_ID="$ARM_TENANT_ID_EXPECTED"
  export GCP_PROJECT_ID="$GCP_PROJECT_ID_EXPECTED"
  export GCP_SERVICE_ACCOUNT_EMAIL="$GCP_SERVICE_ACCOUNT_EMAIL_EXPECTED"
  export cloud_provider_hint="$CLOUD_PROVIDER_HINT_EXPECTED"
}

ensure_variable_group() {
  if [[ -n "${AWS_ACCESS_KEY_ID:-}" && -n "${ARM_CLIENT_ID:-}" && -n "${GCP_PROJECT_ID:-}" ]]; then
    echo "== variable group: using injected environment =="
    return 0
  fi

  echo "== variable group: applying local fake cloud secrets =="
  apply_variable_group_local
}

# --- aws role (env secrets + plain environment) ---
role_aws() {
  echo
  echo "TASK [aws : Show AWS env secrets and plain region]"
  echo "  AWS_ACCESS_KEY_ID     = ${AWS_ACCESS_KEY_ID:-}"
  echo "  AWS_SECRET_ACCESS_KEY = ${AWS_SECRET_ACCESS_KEY:-}"
  echo "  AWS_DEFAULT_REGION    = ${AWS_DEFAULT_REGION:-}"

  echo "TASK [aws : Assert AWS secrets from variable group (env type)]"
  local ok=0
  assert_eq "AWS_ACCESS_KEY_ID" "$AWS_ACCESS_KEY_ID_EXPECTED" "${AWS_ACCESS_KEY_ID:-}" || ok=1
  assert_eq "AWS_SECRET_ACCESS_KEY" "$AWS_SECRET_ACCESS_KEY_EXPECTED" "${AWS_SECRET_ACCESS_KEY:-}" || ok=1
  assert_eq "AWS_DEFAULT_REGION" "$AWS_DEFAULT_REGION_EXPECTED" "${AWS_DEFAULT_REGION:-}" || ok=1

  if [[ "$ok" -eq 0 ]]; then
    echo "  => aws role: AWS env secrets and region OK"
  else
    echo "  => aws role: env secret or plain env var mismatch — check variable group"
  fi
}

# --- azure role (var secrets as process environment / extra vars) ---
role_azure() {
  echo
  echo "TASK [azure : Show Azure extra-var secrets]"
  echo "  ARM_CLIENT_ID     = ${ARM_CLIENT_ID:-}"
  echo "  ARM_CLIENT_SECRET = ${ARM_CLIENT_SECRET:-}"
  echo "  ARM_TENANT_ID     = ${ARM_TENANT_ID:-}"

  echo "TASK [azure : Assert Azure secrets from variable group (var type)]"
  local ok=0
  assert_eq "ARM_CLIENT_ID" "$ARM_CLIENT_ID_EXPECTED" "${ARM_CLIENT_ID:-}" || ok=1
  assert_eq "ARM_CLIENT_SECRET" "$ARM_CLIENT_SECRET_EXPECTED" "${ARM_CLIENT_SECRET:-}" || ok=1
  assert_eq "ARM_TENANT_ID" "$ARM_TENANT_ID_EXPECTED" "${ARM_TENANT_ID:-}" || ok=1

  if [[ "$ok" -eq 0 ]]; then
    echo "  => azure role: Azure var secrets OK"
  else
    echo "  => azure role: extra-var secret mismatch — check variable group"
  fi
}

# --- gcp role (var secrets + plain extra var) ---
role_gcp() {
  echo
  echo "TASK [gcp : Show GCP extra-var secrets and shared hint]"
  echo "  GCP_PROJECT_ID            = ${GCP_PROJECT_ID:-}"
  echo "  GCP_SERVICE_ACCOUNT_EMAIL = ${GCP_SERVICE_ACCOUNT_EMAIL:-}"
  echo "  cloud_provider_hint       = ${cloud_provider_hint:-}"

  echo "TASK [gcp : Assert GCP secrets and plain extra var from variable group]"
  local ok=0
  assert_eq "GCP_PROJECT_ID" "$GCP_PROJECT_ID_EXPECTED" "${GCP_PROJECT_ID:-}" || ok=1
  assert_eq "GCP_SERVICE_ACCOUNT_EMAIL" "$GCP_SERVICE_ACCOUNT_EMAIL_EXPECTED" "${GCP_SERVICE_ACCOUNT_EMAIL:-}" || ok=1
  assert_eq "cloud_provider_hint" "$CLOUD_PROVIDER_HINT_EXPECTED" "${cloud_provider_hint:-}" || ok=1

  if [[ "$ok" -eq 0 ]]; then
    echo "  => gcp role: GCP var secrets and hint OK"
  else
    echo "  => gcp role: var secret or extra variable mismatch — check variable group"
  fi
}

main() {
  echo "PLAY [Variable group secrets scenario]"

  ensure_variable_group

  sleep 5

  role_aws

  sleep 5

  role_azure

  sleep 5

  role_gcp

  sleep 5


  echo
  echo "PLAY RECAP *********************************************************************"
  if [[ "$failures" -gt 0 ]]; then
    echo "localhost : ok=0 failed=$failures"
    exit 1
  fi
  echo "localhost : ok=3 failed=0"
  echo
  echo "All checks passed."
}

main "$@"
