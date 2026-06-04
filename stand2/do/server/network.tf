resource "digitalocean_ssh_key" "default" {
  name       = "${local.prefix}-key"
  public_key = local.ssh_public_key
}

resource "digitalocean_vpc" "main" {
  name     = "${local.prefix}-vpc"
  region   = var.region
  ip_range = local.config.vpc_ip_range
}
