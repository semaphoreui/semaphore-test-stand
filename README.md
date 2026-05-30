# Semaphore Test Stand

A collection of self-contained scenarios for testing
[Semaphore UI](https://semaphoreui.com) against real Ansible workloads.
Each scenario lives under `tests/<name>/` with its own playbook, inventory,
roles, and a `README.md` explaining what it covers and how to wire it in
Semaphore.

## Scenarios

| Scenario | What it covers |
|---|---|
| [`tests/multiple-vault-passwords`](tests/multiple-vault-passwords) | Decrypting three Ansible vault files encrypted with **three different passwords / vault-ids** (`default`, `vault1`, `vault2`) in a single playbook run. Two roles (`webapp`, `monitoring`) consume the shared `default` vault plus their own per-service vault, with `assert` tasks that fail loudly on a wrong password. |
| [`tests/var-group-with-secrets`](tests/var-group-with-secrets) | Variable group **environment**, **extra vars**, and **secrets** (`env` vs `var` types) with fake AWS/Azure/GCP-style credentials; three roles assert each cloud slice received the expected values. |

## Running a scenario locally

Every scenario is a standard Ansible playbook — `cd` into its directory and
run `ansible-playbook` directly. Per-scenario `README.md` shows the exact
flags (vault-ids, extra vars, etc.) needed for that case.

```sh
cd tests/<scenario>
ansible-playbook -i inventory.ini test.yml
```

## Running a scenario in Semaphore

Each scenario's `README.md` includes a **"Wire it into Semaphore"** section
that lists the Key Store credentials, Repository, Inventory, and Task
Template settings required to reproduce the test from the UI.
