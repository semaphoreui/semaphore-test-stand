resource "hcloud_load_balancer" "main" {
  name               = "${var.prefix}-lb"
  load_balancer_type = var.lb_type
  location           = var.lb_location

  labels = {
    role  = "loadbalancer"
    stack = var.prefix
  }
}

# Attach the LB to the private network so it can reach the cluster privately
# and so runners can use a stable internal address.
resource "hcloud_load_balancer_network" "main" {
  load_balancer_id = hcloud_load_balancer.main.id
  subnet_id        = hcloud_network_subnet.main.id
}

# Route the 3 Semaphore UI servers behind the LB via their shared label.
resource "hcloud_load_balancer_target" "cluster" {
  type             = "label_selector"
  load_balancer_id = hcloud_load_balancer.main.id
  label_selector   = "role=semaphore-ui,stack=${var.prefix}"
  use_private_ip   = true

  depends_on = [hcloud_load_balancer_network.main]
}

# HTTP service: public :80 -> Semaphore :3000 with a health check.
resource "hcloud_load_balancer_service" "http" {
  load_balancer_id = hcloud_load_balancer.main.id
  protocol         = "tcp"
  listen_port      = 80
  destination_port = 3000

  health_check {
    protocol = "http"
    port     = 3000
    interval = 10
    timeout  = 5
    retries  = 3

    http {
      path         = "/api/ping"
      status_codes = ["2??", "3??"]
    }
  }
}
