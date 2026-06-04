locals {
  prefix         = "stand2-do-${terraform.workspace}"
  api_token      = sensitive(trimspace(file("${path.module}/../../../keys/${local.prefix}.token")))
  ssh_public_key = file("${path.module}/../../../keys/${local.prefix}.pub")
  dns_zone       = "${local.prefix}.${var.parent_domain}"
  web_root       = "https://${local.dns_zone}"
  api_base_url   = "${local.web_root}/api"
  config         = yamldecode(file("${path.module}/../../../keys/${local.prefix}.config.yml"))
}
