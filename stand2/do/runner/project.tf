data "digitalocean_project" "main" {
  name = local.prefix
}

resource "digitalocean_project_resources" "main" {
  project   = data.digitalocean_project.main.id
  resources = [for d in digitalocean_droplet.runner : d.urn]
}