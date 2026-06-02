provider "digitalocean" {
  token = var.do_token
}

locals {
  api_base_url = "${var.web_root}/api"
}

provider "semaphoreui" {
  api_base_url    = local.api_base_url
  api_token       = var.api_token
  tls_skip_verify = var.tls_skip_verify
}
