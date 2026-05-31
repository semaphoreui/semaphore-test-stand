resource "hcloud_server" "postgres" {
  name        = "${var.prefix}-postgres"
  server_type = var.server_type
  image       = var.image
  location    = var.lb_location

  ssh_keys = [hcloud_ssh_key.default.id]
  labels = {
    role  = "database"
    stack = var.prefix
  }

  # IPv6-only: never needs a public IPv4; reachable internally via the network.
  public_net {
    ipv4_enabled = false
    ipv6_enabled = true
  }

  user_data = templatefile("${path.module}/cloud-init/postgres.yaml.tftpl", {
    db_name       = var.db_name
    db_user       = var.db_user
    db_password   = var.db_password
    db_private_ip = local.db_private_ip
    subnet_cidr   = local.subnet_cidr
  })

  network {
    network_id = hcloud_network.main.id
    ip         = local.db_private_ip
  }

  depends_on = [hcloud_network_subnet.main]
}

resource "hcloud_server" "redis" {
  name        = "${var.prefix}-redis"
  server_type = var.server_type
  image       = var.image
  location    = var.lb_location

  ssh_keys = [hcloud_ssh_key.default.id]
  labels = {
    role  = "redis"
    stack = var.prefix
  }

  # IPv6-only: never needs a public IPv4; reachable internally via the network.
  public_net {
    ipv4_enabled = false
    ipv6_enabled = true
  }

  user_data = templatefile("${path.module}/cloud-init/redis.yaml.tftpl", {
    redis_private_ip = local.redis_private_ip
    redis_password   = var.redis_password
  })

  network {
    network_id = hcloud_network.main.id
    ip         = local.redis_private_ip
  }

  depends_on = [hcloud_network_subnet.main]
}
