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

variable "parent_domain" {
  description = "Parent domain hosted in Cloudflare (e.g. semaphoreui.dev). The '<prefix>.<parent_domain>' sub-zone is delegated to DigitalOcean nameservers."
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token with DNS edit + zone read on the parent domain (or set CLOUDFLARE_API_TOKEN)."
  type        = string
  sensitive   = true
}

variable "lb_subdomain" {
  description = "Label for the load balancer hostname within the delegated zone, i.e. <lb_subdomain>.<prefix>.<parent_domain>."
  type        = string
  default     = "lb"
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

# --- Application secrets / config -------------------------------------------

variable "db_name" {
  description = "PostgreSQL database name for Semaphore."
  type        = string
  default     = "semaphore"
}

variable "db_user" {
  description = "PostgreSQL user for Semaphore."
  type        = string
  default     = "semaphore"
}

variable "db_password" {
  description = "PostgreSQL password for Semaphore."
  type        = string
  sensitive   = true
}

variable "redis_password" {
  description = "Redis password."
  type        = string
  sensitive   = true
}

variable "semaphore_admin_user" {
  description = "Initial Semaphore admin login."
  type        = string
  default     = "admin"
}

variable "semaphore_admin_password" {
  description = "Initial Semaphore admin password."
  type        = string
  sensitive   = true
}

variable "semaphore_admin_email" {
  description = "Initial Semaphore admin email."
  type        = string
  default     = "admin@example.com"
}

variable "semaphore_cookie_hash" {
  description = "Base64 32-byte key used by Semaphore to hash cookies (shared across the cluster). Generate with: head -c32 /dev/urandom | base64"
  type        = string
  sensitive   = true
}

variable "semaphore_cookie_encryption" {
  description = "Base64 32-byte key used by Semaphore to encrypt cookies (shared across the cluster). Generate with: head -c32 /dev/urandom | base64"
  type        = string
  sensitive   = true
}

variable "semaphore_access_key_encryption" {
  description = "Base64 32-byte key used by Semaphore to encrypt access keys (shared across the cluster). Generate with: head -c32 /dev/urandom | base64"
  type        = string
  sensitive   = true
}

variable "runner_registration_token" {
  description = "Token runners use to register with the Semaphore server. Leave empty to configure runners manually after first boot."
  type        = string
  default     = ""
  sensitive   = true
}
