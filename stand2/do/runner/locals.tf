locals {
  api_base_url = "${var.web_root}/api"
  api_token_path = "${path.module}/../../../keys/stand2_${var.prefix}.token"
  api_token = sensitive(trimspace(file(local.api_token_path)))
  ssh_public_key_path = "${path.module}/../../../keys/stand2_${var.prefix}.pub"
  ssh_public_key = file(local.ssh_public_key_path)
}
