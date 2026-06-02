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

  # Unlike DigitalOcean's root droplets, GCE has no root SSH: connect as the
  # key's user and elevate with sudo. The host is the instance's private IP, so
  # Terraform must run with network access to the VPC (e.g. an IAP tunnel, a
  # bastion, or in-VPC) to reach it.
  connection {
    type = "ssh"
    user = var.ssh_user
    host = self.network_interface[0].network_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/semaphore",
      # jq parses the registration-token response; ensure it and curl are present.
      "sudo apt-get update -y",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y jq curl",
    ]
  }

  provisioner "file" {
    content     = <<-EOT
      {
        "web_host": "${var.web_root}",
        "runner": {
          "web_host": "${var.web_root}",
          "token_file": "/etc/semaphore/runner.token",
          "private_key_file": "/etc/semaphore/runner.key",
          "name": "${var.prefix}-${each.value.name}",
          "tags": [
            "local",
            "dev"
          ]
        }
      }
    EOT
    destination = "/tmp/runner-config.json"
  }

  provisioner "file" {
    content     = <<-EOT
      [Unit]
      Description=Semaphore Runner
      Documentation=https://docs.semaphoreui.com
      After=network-online.target
      Wants=network-online.target

      [Service]
      Type=simple
      User=semaphore
      Group=semaphore
      ExecStart=/usr/local/bin/semaphore runner start --config /etc/semaphore/runner-config.json
      Restart=on-failure
      RestartSec=5

      [Install]
      WantedBy=multi-user.target
    EOT
    destination = "/tmp/semaphore-runner.service"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/runner-config.json /etc/semaphore/runner-config.json",
      "sudo mv /tmp/semaphore-runner.service /etc/systemd/system/semaphore-runner.service",

      "curl -o semaphore_${var.semaphore_version}_linux_amd64.tar.gz -L https://github.com/semaphoreui/semaphore/releases/download/v${var.semaphore_version}/semaphore_${var.semaphore_version}_linux_amd64.tar.gz",
      "tar xf semaphore_${var.semaphore_version}_linux_amd64.tar.gz",
      "sudo mv semaphore /usr/local/bin/",

      "id -u semaphore >/dev/null 2>&1 || sudo useradd --system --no-create-home --shell /usr/sbin/nologin semaphore",
      "sudo chmod 0600 /etc/semaphore/runner-config.json",
      "sudo chmod 0644 /etc/systemd/system/semaphore-runner.service",
      "sudo chown -R semaphore:semaphore /etc/semaphore",
      "sudo systemctl daemon-reload",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      <<-EOT
        curl -XPOST \
          -H 'Authorization: Bearer ${var.api_token}' \
          -H 'content-type: application/json' \
          ${local.api_base_url}/runners/${semaphoreui_runner.runner[each.key].id}/registration-token \
          | jq -r .registration_token \
          | sudo /usr/local/bin/semaphore runner register \
              --stdin-registration-token \
              --config /etc/semaphore/runner-config.json
      EOT
      ,
      "sudo systemctl enable --now semaphore-runner",
    ]
  }
}
