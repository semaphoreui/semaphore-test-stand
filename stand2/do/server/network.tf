resource "digitalocean_ssh_key" "default" {
  name       = "${local.prefix}-key"
  public_key = local.ssh_public_key
}

resource "digitalocean_vpc" "main" {
  name     = "${local.prefix}-cluster-vpc"
  region   = var.region
  ip_range = local.config.cluster_ip_range
}
