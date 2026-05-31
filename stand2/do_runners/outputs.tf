output "runner_servers" {
  description = "Semaphore runner droplets."
  value = {
    for d in digitalocean_droplet.runner : d.name => {
      region     = d.region
      public_ip  = d.ipv4_address
      private_ip = d.ipv4_address_private
    }
  }
}
