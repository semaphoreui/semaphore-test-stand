provider "digitalocean" {
  token = var.do_token
}

locals {
  api_base_url = "${var.web_root}/api"
  api_token = sensitive(trimspace(file("${path.module}/admin.token")))
}

provider "semaphoreui" {
  api_base_url    = local.api_base_url
  api_token       = local.api_token
  tls_skip_verify = false
}
