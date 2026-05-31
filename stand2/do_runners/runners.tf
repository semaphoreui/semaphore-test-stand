# 3 Semaphore runner droplets. They reach the cluster through the load balancer.
resource "digitalocean_droplet" "runner" {
  count    = 3
  name     = "${var.prefix}-runner-${count.index + 1}"
  image    = var.image
  size     = var.size
  region   = var.region
  vpc_uuid = digitalocean_vpc.main.id

  ssh_keys = [digitalocean_ssh_key.default.id]
  tags     = [digitalocean_tag.runner.id, digitalocean_tag.runner.id]

  user_data = templatefile("${path.module}/cloud-init/runner-systemd.yaml.tftpl", {
    web_root           = "https://lb.stand2.semaphoreui.dev"
  })
}
