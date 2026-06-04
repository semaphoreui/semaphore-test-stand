# Groups the deployment in its own DigitalOcean project. Only resources that
# support project assignment (droplets, load balancers) are listed here — VPCs,
# firewalls, tags and SSH keys are account/region-scoped and cannot be bound.
resource "digitalocean_project" "main" {
  name        = local.prefix
  description = "Semaphore UI cluster"
  purpose     = "Web Application"
  environment = var.project_environment

  resources = concat(
    [for d in digitalocean_droplet.cluster : d.urn],
    # [for d in digitalocean_droplet.runner : d.urn],
    [
      digitalocean_droplet.postgres.urn,
      digitalocean_droplet.redis.urn,
      digitalocean_loadbalancer.main.urn,
    ],
  )
}
