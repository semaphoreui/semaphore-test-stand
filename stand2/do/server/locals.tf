locals {
  prefix         = "stand2-do-${terraform.workspace}"
  api_token_path = "${path.module}/../../../keys/${local.prefix}/admin.token"
  api_token      = sensitive(trimspace(file(local.api_token_path)))
  ssh_public_key = file(var.ssh_public_key_path)
  dns_zone       = "${local.prefix}.${var.parent_domain}"
  web_root       = "https://lb.${local.dns_zone}"
  api_base_url   = "${local.web_root}/api"
  config         = yamldecode(file("${path.module}/../../../keys/${local.prefix}/config.yml"))
}
