data "digitalocean_ssh_key" "default" {
  name = "${var.prefix}-key"
}

data "digitalocean_vpc" "main" {
  name = "${var.prefix}-vpc"
}
