provider "digitalocean" {
  token = var.do_token
}

locals {
  api_base_url = "${var.web_root}/api"
  # Read the Semaphore API token from the file the server stack writes. trimspace
  # drops the trailing newline; sensitive() keeps it out of plan/CLI output.
  api_token = sensitive(trimspace(file("${path.module}/${var.api_token_file}")))
}

provider "semaphoreui" {
  api_base_url    = local.api_base_url
  api_token       = local.api_token
  tls_skip_verify = false
}
