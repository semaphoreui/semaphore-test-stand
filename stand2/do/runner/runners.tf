resource "semaphoreui_runner" "runner" {
  for_each           = local.config.runners
  name               = each.value.name
  max_parallel_tasks = 500
  active             = true
  tags               = ["local", "dev"]
}

resource "digitalocean_droplet" "runner" {
  for_each = local.config.runners

  name     = "runner-${semaphoreui_runner.runner[each.key].id}-${each.value.name}"
  image    = var.image
  size     = var.size
  region   = var.region
  vpc_uuid = digitalocean_vpc.main.id

  ssh_keys = [local.no_server ? digitalocean_ssh_key.default[0].id : data.digitalocean_ssh_key.default[0].id]
  tags     = [digitalocean_tag.runner.id]

  user_data = templatefile("${path.module}/../../shared/cloud-init/runner-systemd.yaml.tftpl", {})

  connection {
    type = "ssh"
    user = "root"
    host = self.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /etc/semaphore",
    ]
  }

  provisioner "file" {
    content = templatefile("${path.module}/../../shared/runner/runner-config.json.tftpl", {
      web_root    = local.web_root
      runner_name = "${local.prefix}-${each.value.name}"
      tags        = ["local", "dev"]
    })
    destination = "/etc/semaphore/runner-config.json"
  }

  provisioner "file" {
    content     = file("${path.module}/../../shared/runner/semaphore-runner.service")
    destination = "/etc/systemd/system/semaphore-runner.service"
  }

  provisioner "remote-exec" {
    inline = [
      "curl -o semaphore_${var.semaphore_version}_linux_amd64.tar.gz -L https://github.com/semaphoreui/semaphore/releases/download/v${var.semaphore_version}/semaphore_${var.semaphore_version}_linux_amd64.tar.gz",
      "tar xf semaphore_${var.semaphore_version}_linux_amd64.tar.gz",
      "mv semaphore /usr/local/bin/",

      "id -u semaphore >/dev/null 2>&1 || useradd --system --create-home --shell /usr/sbin/nologin semaphore",
      "chmod 0600 /etc/semaphore/runner-config.json",
      "chmod 0644 /etc/systemd/system/semaphore-runner.service",
      "chown -R semaphore:semaphore /etc/semaphore",
      "systemctl daemon-reload",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      <<-EOT
        curl -XPOST -s \
          -H 'Authorization: Bearer ${local.api_token}' \
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
