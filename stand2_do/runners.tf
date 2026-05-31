# 3 Semaphore runner droplets. They reach the cluster through the load balancer.
resource "digitalocean_droplet" "runner" {
  count    = 3
  name     = "${var.prefix}-runner-${count.index + 1}"
  image    = var.image
  size     = var.size
  region   = var.region
  vpc_uuid = digitalocean_vpc.main.id

  ssh_keys = [digitalocean_ssh_key.default.id]
  tags     = [digitalocean_tag.base.id, digitalocean_tag.runner.id]

  user_data = templatefile("${path.module}/cloud-init/runner.yaml.tftpl", {
    server_host        = digitalocean_loadbalancer.main.ip
    registration_token = var.runner_registration_token
  })
}
