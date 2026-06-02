output "runner_servers" {
  description = "Semaphore runner instances."
  value = {
    for i in google_compute_instance.runner : i.name => {
      zone       = i.zone
      public_ip  = i.network_interface[0].access_config[0].nat_ip
      private_ip = i.network_interface[0].network_ip
    }
  }
}
