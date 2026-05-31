# 3 Semaphore UI servers, one per zone, fronted by the load balancer.
resource "hcloud_server" "cluster" {
  count       = 3
  name        = "${var.prefix}-ui-${count.index + 1}"
  server_type = var.server_type
  image       = var.image
  location    = var.cluster_locations[count.index]

  ssh_keys = [hcloud_ssh_key.default.id]
  labels = {
    role  = "semaphore-ui"
    stack = var.prefix
  }

  user_data = templatefile("${path.module}/cloud-init/semaphore.yaml.tftpl", {
    db_host               = local.db_private_ip
    db_name               = var.db_name
    db_user               = var.db_user
    db_password           = var.db_password
    redis_host            = local.redis_private_ip
    redis_password        = var.redis_password
    access_key_encryption = var.semaphore_access_key_encryption
    admin_user            = var.semaphore_admin_user
    admin_password        = var.semaphore_admin_password
    admin_email           = var.semaphore_admin_email
  })

  network {
    network_id = hcloud_network.main.id
    ip         = local.cluster_private_ips[count.index]
  }

  depends_on = [
    hcloud_network_subnet.main,
    hcloud_server.postgres,
    hcloud_server.redis,
  ]
}
