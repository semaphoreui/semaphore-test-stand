variable "runners" {
  type = map(object({
    name = string
  }))
}

# Declare each runner in Semaphore. Its ID is used below to mint a one-time
# registration token the instance redeems on first boot.
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
    # Installs the runner, fetches a registration token from the Semaphore API
    # using this runner's ID, registers, and starts the systemd service.
    user-data = templatefile("${path.module}/cloud-init/runner-docker.yaml.tftpl", {
      web_root          = var.web_root
      api_base_url      = local.api_base_url
      api_token         = var.api_token
      runner_id         = semaphoreui_runner.runner[each.key].id
      semaphore_version = var.semaphore_version
    })
  }
}
