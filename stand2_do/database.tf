resource "digitalocean_droplet" "postgres" {
  name     = "${var.prefix}-postgres"
  image    = var.image
  size     = var.size
  region   = var.region
  vpc_uuid = digitalocean_vpc.main.id

  ssh_keys = [digitalocean_ssh_key.default.id]
  tags     = [digitalocean_tag.base.id, digitalocean_tag.database.id]

  user_data = templatefile("${path.module}/cloud-init/postgres.yaml.tftpl", {
    db_name      = var.db_name
    db_user      = var.db_user
    db_password  = var.db_password
    vpc_ip_range = var.vpc_ip_range
  })
}

resource "digitalocean_droplet" "redis" {
  name     = "${var.prefix}-redis"
  image    = var.image
  size     = var.size
  region   = var.region
  vpc_uuid = digitalocean_vpc.main.id

  ssh_keys = [digitalocean_ssh_key.default.id]
  tags     = [digitalocean_tag.base.id, digitalocean_tag.redis.id]

  user_data = templatefile("${path.module}/cloud-init/redis.yaml.tftpl", {
    redis_password = var.redis_password
  })
}
