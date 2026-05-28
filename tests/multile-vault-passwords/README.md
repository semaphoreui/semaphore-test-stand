# Multiple Vault Passwords — test scenario

Verifies that Ansible (and Semaphore) can decrypt three vault files that were
encrypted with **three different passwords** in a single run.

## Layout

```
tests/multile-vault-passwords/
├── test.yml                    # entrypoint playbook (localhost)
├── inventory.ini               # local-only inventory
├── files/
│   ├── secrets-default.yml     # encrypted with vault-id "default" / password "defaultpass"
│   ├── secrets1.yml            # encrypted with vault-id "vault1"  / password "pass1"
│   └── secrets2.yml            # encrypted with vault-id "vault2"  / password "pass2"
└── roles/
    ├── webapp/                 # consumes secrets-default.yml + secrets1.yml
    └── monitoring/             # consumes secrets-default.yml + secrets2.yml
```

Each role:

1. `include_vars`-loads its two vault files into separate namespaces.
2. Prints the decrypted values with `debug`.
3. `assert`s the plaintext matches the expected fingerprint — so a missed or
   wrong password makes the playbook fail loudly instead of silently using
   garbage.

## Vault id → password map

| File                  | vault-id  | password      |
|-----------------------|-----------|---------------|
| `secrets-default.yml` | `default` | `defaultpass` |
| `secrets1.yml`        | `vault1`  | `pass1`       |
| `secrets2.yml`        | `vault2`  | `pass2`       |

The `default` id is reserved by Ansible: files encrypted under it are stored
without a label in the header, so any vault-id can decrypt them. The other two
files carry their label in the `$ANSIBLE_VAULT;1.2;AES256;<label>` header, so
Ansible auto-routes them to the matching password.

## Run locally

```sh
cd tests/multile-vault-passwords

# one-shot: feed all three passwords via stdin-prompt
ansible-playbook -i inventory.ini test.yml \
  --vault-id default@prompt \
  --vault-id vault1@prompt \
  --vault-id vault2@prompt

# or with password files
echo defaultpass > /tmp/pw_default && chmod 600 /tmp/pw_default
echo pass1       > /tmp/pw_v1      && chmod 600 /tmp/pw_v1
echo pass2       > /tmp/pw_v2      && chmod 600 /tmp/pw_v2

ansible-playbook -i inventory.ini test.yml \
  --vault-id default@/tmp/pw_default \
  --vault-id vault1@/tmp/pw_v1 \
  --vault-id vault2@/tmp/pw_v2
```

Expected outcome: both `assert` tasks print their `success_msg` and the
play ends with `failed=0`.

## Wire it into Semaphore

1. **Key Store →** create three `Vault Password` credentials:
   - name `vault_default`, vault-id `default`, password `defaultpass`
   - name `vault_1`,       vault-id `vault1`,  password `pass1`
   - name `vault_2`,       vault-id `vault2`,  password `pass2`
2. **Repository →** point at this repo.
3. **Inventory →** static, contents `localhost ansible_connection=local`.
4. **Task Template →**
   - playbook: `tests/multile-vault-passwords/test.yml`
   - in the **Vault Password** field, attach all three credentials.
5. Run. Semaphore will pass `--vault-id default@…`, `--vault-id vault1@…`,
   `--vault-id vault2@…` to `ansible-playbook`, and the assert tasks will
   confirm every file decrypted correctly.

## Negative checks (optional)

- Run with only one of the three `--vault-id` flags → expect
  `ERROR! Attempting to decrypt but no vault secrets found` on the role that
  needs the missing one.
- Swap two passwords (e.g. give `vault1` the value `pass2`) → expect
  `Decryption failed (no vault secrets were found that could decrypt)`.
