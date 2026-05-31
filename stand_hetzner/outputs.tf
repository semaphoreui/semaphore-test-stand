output "load_balancer_public_ip" {
  description = "Public IPv4 of the load balancer (Semaphore UI entry point on :80)."
  value       = hcloud_load_balancer.main.ipv4
}

output "load_balancer_private_ip" {
  description = "Private IP of the load balancer inside the network."
  value       = hcloud_load_balancer_network.main.ip
}

output "cluster_servers" {
  description = "Semaphore UI cluster servers."
  value = {
    for s in hcloud_server.cluster : s.name => {
      location   = s.location
      public_ip  = s.ipv4_address
      private_ip = one([for n in s.network : n.ip])
    }
  }
}

output "runner_servers" {
  description = "Semaphore runner servers."
  value = {
    for s in hcloud_server.runner : s.name => {
      location   = s.location
      public_ip  = s.ipv4_address
      private_ip = one([for n in s.network : n.ip])
    }
  }
}

output "postgres_server" {
  description = "PostgreSQL server (IPv6-only, internal access via private_ip)."
  value = {
    public_ipv6 = hcloud_server.postgres.ipv6_address
    private_ip  = local.db_private_ip
  }
}

output "redis_server" {
  description = "Redis server (IPv6-only, internal access via private_ip)."
  value = {
    public_ipv6 = hcloud_server.redis.ipv6_address
    private_ip  = local.redis_private_ip
  }
}
