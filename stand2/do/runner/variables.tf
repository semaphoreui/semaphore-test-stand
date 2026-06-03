variable "do_token" {
  description = "DigitalOcean API token (or set DIGITALOCEAN_TOKEN)."
  type        = string
  sensitive   = true
}

variable "prefix" {
  description = "Name prefix applied to every resource."
  type        = string
  default     = "semaphore"
}

variable "ssh_public_key" {
  description = "SSH public key contents granted access to every droplet."
  type        = string
}

variable "size" {
  description = "Droplet size slug used for all 'small' droplets."
  type        = string
  default     = "s-1vcpu-2gb"
}

variable "image" {
  description = "OS image slug for all droplets."
  type        = string
  default     = "ubuntu-24-04-x64"
}

variable "region" {
  description = <<-EOT
    DigitalOcean region for all resources. DigitalOcean does not expose
    availability zones, and a VPC + load balancer are regional, so the whole
    cluster lives in one region.
  EOT
  type        = string
  default     = "fra1"
}

variable "web_root" {
  description = "Semaphore API base URL (or set SEMAPHOREUI_API_BASE_URL)."
  type        = string
  default     = "https://localhost:3000"
}

variable "semaphore_version" {
  description = "Semaphore runner version (or set SEMAPHORE_RUNNER_VERSION)."
  type        = string
  default     = "2.18.6-beta1"
}

variable "api_token_file" {
  description = "Path (relative to this module) to the file holding the Semaphore API token, produced by the server stack."
  type        = string
  default     = "../server/admin.token"
}