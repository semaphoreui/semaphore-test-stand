data "digitalocean_ssh_key" "default" {
  name = "${local.prefix}-key"
}

data "digitalocean_vpc" "main" {
  name = "${local.prefix}-vpc"
}
