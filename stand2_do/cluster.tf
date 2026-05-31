# 3 Semaphore UI droplets behind the load balancer. DigitalOcean has no
# availability zones, so they share one region/VPC. Private IPs of Postgres
# and Redis are resolved from their droplet resources (created first).
resource "digitalocean_droplet" "cluster" {
  count    = 3
  name     = "${var.prefix}-ui-${count.index + 1}"
  image    = var.image
  size     = var.size
  region   = var.region
  vpc_uuid = digitalocean_vpc.main.id

  ssh_keys = [digitalocean_ssh_key.default.id]
  tags     = [digitalocean_tag.base.id, digitalocean_tag.ui.id]

  user_data = templatefile("${path.module}/cloud-init/semaphore.yaml.tftpl", {
    db_host               = digitalocean_droplet.postgres.ipv4_address_private
    db_name               = var.db_name
    db_user               = var.db_user
    db_password           = var.db_password
    redis_host            = digitalocean_droplet.redis.ipv4_address_private
    redis_password        = var.redis_password
    web_root              = "https://${local.lb_fqdn}"
    access_key_encryption = var.semaphore_access_key_encryption
    admin_user            = var.semaphore_admin_user
    admin_password        = var.semaphore_admin_password
    admin_email           = var.semaphore_admin_email
  })
}
