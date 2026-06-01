resource "semaphoreui_runner" "runner" {
  name               = "local-dev-runner"
  max_parallel_tasks = 1
  active             = true
  tags               = ["local", "dev"]
}

# 3 Semaphore runner droplets. They reach the cluster through the load balancer.
resource "digitalocean_droplet" "runner" {
  count    = 1
  name     = "${var.prefix}-runner-${count.index + 1}"
  image    = var.image
  size     = var.size
  region   = var.region
  vpc_uuid = data.digitalocean_vpc.main.id

  ssh_keys = [data.digitalocean_ssh_key.default.id]
  tags     = [digitalocean_tag.runner.id, digitalocean_tag.runner.id]

  user_data = templatefile("${path.module}/cloud-init/runner-systemd.yaml.tftpl", {
    web_root           = "https://lb.stand2.semaphoreui.dev",
    runner_registration_token = semaphoreui_runner.runner.registration_token,
  })
}
