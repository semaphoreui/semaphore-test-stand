variable "runners" {
  type = map(object({
    name               = string
  }))
}

resource "semaphoreui_runner" "runner" {
  for_each           = var.runners
  name               = "${var.prefix}-${each.value.name}"
  max_parallel_tasks = 1
  active             = true
  tags               = ["local", "dev"]
}

resource "digitalocean_droplet" "runner" {
  for_each = var.runners

  name     = "${var.prefix}-${each.value.name}"
  image    = var.image
  size     = var.size
  region   = var.region
  vpc_uuid = data.digitalocean_vpc.main.id

  ssh_keys = [data.digitalocean_ssh_key.default.id]
  tags     = [digitalocean_tag.runner.id, digitalocean_tag.runner.id]

  connection {
    type        = "ssh"
    user        = "root"
    host        = self.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /etc/semaphore",
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
          "name": "Denis's project 39 runner",
          "tags": [
            "denis-project-39"
          ]
        }
      }
    EOT
    destination = "/etc/semaphore/runner-config.json"
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
    destination = "/etc/systemd/system/semaphore-runner.service"
  }

  provisioner "remote-exec" {
    inline = [
      "curl -o semaphore_${var.semaphore_version}_linux_amd64.tar.gz -L https://github.com/semaphoreui/semaphore/releases/download/v${var.semaphore_version}/semaphore_${var.semaphore_version}_linux_amd64.tar.gz",
      "tar xf semaphore_${var.semaphore_version}_linux_amd64.tar.gz",
      "mv semaphore /usr/local/bin/",
      
      "id -u semaphore >/dev/null 2>&1 || useradd --system --no-create-home --shell /usr/sbin/nologin semaphore",
      "chmod 0600 /etc/semaphore/runner-config.json",
      "chmod 0644 /etc/systemd/system/semaphore-runner.service",
      "chown -R semaphore:semaphore /etc/semaphore",
      "systemctl daemon-reload",
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
          | /usr/local/bin/semaphore runner register \
              --stdin-registration-token \
              --config /etc/semaphore/runner-config.json
      EOT
      ,
      "systemctl enable --now semaphore-runner",
    ]
  }
}
