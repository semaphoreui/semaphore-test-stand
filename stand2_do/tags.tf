# Tags must exist before firewalls / load balancers reference them, so they
# are declared as first-class resources rather than inline droplet tag strings.
resource "digitalocean_tag" "base" {
  name = var.prefix
}

resource "digitalocean_tag" "ui" {
  name = "${var.prefix}-ui"
}

resource "digitalocean_tag" "runner" {
  name = "${var.prefix}-runner"
}

resource "digitalocean_tag" "database" {
  name = "${var.prefix}-database"
}

resource "digitalocean_tag" "redis" {
  name = "${var.prefix}-redis"
}
