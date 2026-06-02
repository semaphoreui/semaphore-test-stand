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

variable "project_environment" {
  description = "DigitalOcean project environment (Development, Staging, or Production)."
  type        = string
  default     = "Development"
}

variable "vpc_ip_range" {
  description = "Private VPC CIDR. Postgres allows connections from this range."
  type        = string
  default     = "10.10.10.0/24"
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

# variable "tls_skip_verify" {
#   description = "Skip TLS verification for the API (local HTTPS with a self-signed cert)."
#   type        = bool
#   default     = true
# }

variable "api_token" {
  description = "Semaphore API token (or set SEMAPHOREUI_API_TOKEN)."
  type        = string
  sensitive   = true
}
