variable "runners" {
  type = map(object({
    name = string
  }))
}

# Declare each runner in Semaphore. Its ID is used below to mint a one-time
# registration token the instance redeems during provisioning.
resource "semaphoreui_runner" "runner" {
  for_each           = var.runners
  name               = "${var.prefix}-${each.value.name}"
  max_parallel_tasks = 1
  active             = true
  tags               = ["local", "dev"]
}

resource "google_compute_instance" "runner" {
  for_each = var.runners

  name         = "${var.prefix}-${each.value.name}"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = [local.tag_runner]

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    subnetwork = data.google_compute_subnetwork.main.id
    # No external IP — outbound via the server stack's Cloud NAT (org policy
    # forbids external IPs).
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${var.ssh_public_key}"
  }
}

# The instances have no public IP (org policy), so Terraform cannot SSH to them
# directly. Provisioning therefore runs locally via `gcloud ... --tunnel-through-iap`,
# which reaches the private instance over Google's Identity-Aware Proxy. This
# requires the gcloud CLI to be authenticated (`gcloud auth login`) and the
# caller to hold roles/iap.tunnelResourceAccessor on the project.
resource "terraform_data" "provision" {
  for_each = var.runners

  # Re-run provisioning if the instance or the Semaphore runner is recreated.
  triggers_replace = [
    google_compute_instance.runner[each.key].id,
    semaphoreui_runner.runner[each.key].id,
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    environment = {
      PROJECT  = var.gcp_project
      ZONE     = var.zone
      INSTANCE = google_compute_instance.runner[each.key].name
      # Fully rendered by Terraform (secrets included); passed as a single env
      # var to avoid heredoc/indentation pitfalls.
      PROVISION_SCRIPT = templatefile("${path.module}/provision.sh.tftpl", {
        web_root          = var.web_root
        api_base_url      = local.api_base_url
        api_token         = var.api_token
        runner_id         = semaphoreui_runner.runner[each.key].id
        semaphore_version = var.semaphore_version
        runner_name       = "${var.prefix}-${each.value.name}"
      })
    }

    command = <<-EOT
      set -euo pipefail
      TMP=$(mktemp -d)
      printf '%s' "$PROVISION_SCRIPT" > "$TMP/provision.sh"

      echo "Waiting for SSH (IAP) on $INSTANCE ..."
      for i in $(seq 1 30); do
        if gcloud compute ssh "$INSTANCE" --zone "$ZONE" --project "$PROJECT" \
             --tunnel-through-iap --quiet --command "true" 2>/dev/null; then
          break
        fi
        sleep 10
      done

      # Ship the script over IAP and run it with sudo on the private instance.
      gcloud compute scp "$TMP/provision.sh" "$INSTANCE":/tmp/provision.sh \
        --zone "$ZONE" --project "$PROJECT" --tunnel-through-iap --quiet

      gcloud compute ssh "$INSTANCE" --zone "$ZONE" --project "$PROJECT" \
        --tunnel-through-iap --quiet --command "sudo bash /tmp/provision.sh"
    EOT
  }
}
