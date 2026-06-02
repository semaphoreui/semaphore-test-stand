# Authentication is taken from the environment: run `gcloud auth application-default
# login` or set GOOGLE_APPLICATION_CREDENTIALS to a service-account key file.
provider "google" {
  project = var.gcp_project
  region  = var.region
  zone    = var.zone
}

locals {
  api_base_url = "${var.web_root}/api"
}

provider "semaphoreui" {
  api_base_url    = local.api_base_url
  api_token       = var.api_token
  tls_skip_verify = false
}
