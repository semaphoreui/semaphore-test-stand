locals {
  network_cidr = "10.0.0.0/16"
  subnet_cidr  = "10.0.1.0/24"

  # Static private IPs so cloud-init can wire services together at boot time
  # without creating dependency cycles between servers.
  db_private_ip    = "10.0.1.10"
  redis_private_ip = "10.0.1.11"

  cluster_private_ips = ["10.0.1.21", "10.0.1.22", "10.0.1.23"]
  runner_private_ips  = ["10.0.1.31", "10.0.1.32", "10.0.1.33"]
}

resource "hcloud_ssh_key" "default" {
  name       = "${var.prefix}-key"
  public_key = var.ssh_public_key
}

resource "hcloud_network" "main" {
  name     = "${var.prefix}-net"
  ip_range = local.network_cidr
}

resource "hcloud_network_subnet" "main" {
  network_id   = hcloud_network.main.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = local.subnet_cidr
}
