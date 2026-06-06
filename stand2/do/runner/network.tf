resource "digitalocean_vpc" "main" {
  name      = "${local.prefix}-runners-vpc"
  region    = var.region
  ip_range  = local.config.runners_ip_range
}

resource "digitalocean_ssh_key" "default" {
  count      = local.no_server ? 1 : 0
  name       = "${local.prefix}-key"
  public_key = local.ssh_public_key
}

data "digitalocean_ssh_key" "default" {
  count     = local.no_server ? 0 : 1
  name = "${local.prefix}-key"
}