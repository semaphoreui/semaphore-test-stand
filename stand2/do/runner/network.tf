resource "digitalocean_ssh_key" "default" {
  count      = local.no_server ? 1 : 0
  name       = "${local.prefix}-key"
  public_key = local.ssh_public_key
}

resource "digitalocean_vpc" "main" {
  count     = local.no_server ? 1 : 0
  name      = "${local.prefix}-vpc"
  region    = var.region
  ip_range  = local.config.vpc_ip_range
}

data "digitalocean_ssh_key" "default" {
  count     = local.no_server ? 0 : 1
  name = "${local.prefix}-key"
}

data "digitalocean_vpc" "main" {
  count     = local.no_server ? 0 : 1
  name = "${local.prefix}-vpc"
}
