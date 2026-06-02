resource "digitalocean_ssh_key" "default" {
  name       = "${var.prefix}-key"
  public_key = var.ssh_public_key
}

resource "digitalocean_vpc" "main" {
  name     = "${var.prefix}-vpc"
  region   = var.region
  ip_range = var.vpc_ip_range
}
