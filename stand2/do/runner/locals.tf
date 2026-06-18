locals {
  prefix         = "stand2-do-${terraform.workspace}"
  api_token      = sensitive(trimspace(file("${path.module}/../../../keys/${local.prefix}/admin.token")))
  dns_zone       = "${local.prefix}.${var.parent_domain}"
  web_root       = var.web_root != "" ? var.web_root : "https://lb.${local.dns_zone}"
  api_base_url   = "${local.web_root}/api"
  config         = yamldecode(file("${path.module}/../../../keys/${local.prefix}/config.yml"))
  no_server      = var.web_root != ""
}
