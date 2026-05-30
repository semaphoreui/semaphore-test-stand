#!/usr/bin/env bash
# Simulate Semaphore variable group "cloud-secrets" locally, verify in Bash,
# then run the Ansible playbook with the same values.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# --- expected values (match stands/stand1/environment_cloud_secrets.tf) ---
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
    echo "  actual:   $actual"
    failures=$((failures + 1))
  else
    echo "OK:   $name"
  fi
}

# Mimics Semaphore variable group injection before Ansible runs.
apply_variable_group() {
  # secret type "env" + plain environment
  export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID_EXPECTED"
  export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY_EXPECTED"
  export AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION_EXPECTED"

  # secret type "var" + plain extra variable (passed to ansible-playbook -e)
  ARM_CLIENT_ID="$ARM_CLIENT_ID_EXPECTED"
  ARM_CLIENT_SECRET="$ARM_CLIENT_SECRET_EXPECTED"
  ARM_TENANT_ID="$ARM_TENANT_ID_EXPECTED"
  GCP_PROJECT_ID="$GCP_PROJECT_ID_EXPECTED"
  GCP_SERVICE_ACCOUNT_EMAIL="$GCP_SERVICE_ACCOUNT_EMAIL_EXPECTED"
  cloud_provider_hint="$CLOUD_PROVIDER_HINT_EXPECTED"
  export ARM_CLIENT_ID ARM_CLIENT_SECRET ARM_TENANT_ID
  export GCP_PROJECT_ID GCP_SERVICE_ACCOUNT_EMAIL cloud_provider_hint
}

test_aws_env_secrets() {
  echo "--- aws (env secrets + plain environment) ---"
  assert_eq "AWS_ACCESS_KEY_ID" "$AWS_ACCESS_KEY_ID_EXPECTED" "${AWS_ACCESS_KEY_ID:-}"
  assert_eq "AWS_SECRET_ACCESS_KEY" "$AWS_SECRET_ACCESS_KEY_EXPECTED" "${AWS_SECRET_ACCESS_KEY:-}"
  assert_eq "AWS_DEFAULT_REGION" "$AWS_DEFAULT_REGION_EXPECTED" "${AWS_DEFAULT_REGION:-}"
}

test_azure_var_secrets() {
  echo "--- azure (var secrets → extra vars) ---"
  assert_eq "ARM_CLIENT_ID" "$ARM_CLIENT_ID_EXPECTED" "${ARM_CLIENT_ID:-}"
  assert_eq "ARM_CLIENT_SECRET" "$ARM_CLIENT_SECRET_EXPECTED" "${ARM_CLIENT_SECRET:-}"
  assert_eq "ARM_TENANT_ID" "$ARM_TENANT_ID_EXPECTED" "${ARM_TENANT_ID:-}"
}

test_gcp_var_secrets() {
  echo "--- gcp (var secrets + plain extra var) ---"
  assert_eq "GCP_PROJECT_ID" "$GCP_PROJECT_ID_EXPECTED" "${GCP_PROJECT_ID:-}"
  assert_eq "GCP_SERVICE_ACCOUNT_EMAIL" "$GCP_SERVICE_ACCOUNT_EMAIL_EXPECTED" "${GCP_SERVICE_ACCOUNT_EMAIL:-}"
  assert_eq "cloud_provider_hint" "$CLOUD_PROVIDER_HINT_EXPECTED" "${cloud_provider_hint:-}"
}

run_ansible_playbook() {
  echo "--- ansible-playbook ---"
  if ! command -v ansible-playbook >/dev/null 2>&1; then
    echo "SKIP: ansible-playbook not found"
    return 0
  fi

  ansible-playbook -i inventory.ini test.yml \
    -e "cloud_provider_hint=${cloud_provider_hint}" \
    -e "ARM_CLIENT_ID=${ARM_CLIENT_ID}" \
    -e "ARM_CLIENT_SECRET=${ARM_CLIENT_SECRET}" \
    -e "ARM_TENANT_ID=${ARM_TENANT_ID}" \
    -e "GCP_PROJECT_ID=${GCP_PROJECT_ID}" \
    -e "GCP_SERVICE_ACCOUNT_EMAIL=${GCP_SERVICE_ACCOUNT_EMAIL}"
}

main() {
  echo "== var-group-with-secrets: apply variable group =="
  apply_variable_group

  echo
  echo "== Bash checks (same assertions as Ansible roles) =="
  test_aws_env_secrets
  test_azure_var_secrets
  test_gcp_var_secrets

  if [[ "$failures" -gt 0 ]]; then
    echo
    echo "$failures bash assertion(s) failed"
    exit 1
  fi

  echo
  run_ansible_playbook
  echo
  echo "All checks passed."
}

main "$@"
