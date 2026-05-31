# 3 Semaphore runner servers. They reach the cluster through the load balancer.
resource "hcloud_server" "runner" {
  count       = 3
  name        = "${var.prefix}-runner-${count.index + 1}"
  server_type = var.server_type
  image       = var.image
  location    = var.runner_locations[count.index]

  ssh_keys = [hcloud_ssh_key.default.id]
  labels = {
    role  = "semaphore-runner"
    stack = var.prefix
  }

  user_data = templatefile("${path.module}/cloud-init/runner.yaml.tftpl", {
    # Runners talk to the cluster over the private network via the LB.
    server_host        = hcloud_load_balancer_network.main.ip
    registration_token = var.runner_registration_token
  })

  network {
    network_id = hcloud_network.main.id
    ip         = local.runner_private_ips[count.index]
  }

  depends_on = [
    hcloud_network_subnet.main,
    hcloud_load_balancer_network.main,
  ]
}
