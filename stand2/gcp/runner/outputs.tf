# Instances have no external IP (org policy); only private IPs are surfaced.
output "runner_servers" {
  description = "Semaphore runner instances."
  value = {
    for i in google_compute_instance.runner : i.name => {
      zone       = i.zone
      private_ip = i.network_interface[0].network_ip
    }
  }
}
