variable "hcloud_token" {
  description = "Hetzner Cloud API token (or set HCLOUD_TOKEN)."
  type        = string
  sensitive   = true
}

variable "prefix" {
  description = "Name prefix applied to every resource."
  type        = string
  default     = "semaphore"
}

variable "ssh_public_key" {
  description = "SSH public key contents granted access to every server."
  type        = string
}

variable "server_type" {
  description = "Hetzner server type used for all 'small' servers."
  type        = string
  default     = "cx23" # 2 vCPU / 4 GB shared (smallest x86 in fsn1/nbg1/hel1)
}

variable "lb_type" {
  description = "Hetzner load balancer type."
  type        = string
  default     = "lb11"
}

variable "image" {
  description = "OS image for all servers."
  type        = string
  default     = "ubuntu-24.04"
}

variable "lb_location" {
  description = "Location for the load balancer (must be in the network zone)."
  type        = string
  default     = "fsn1"
}

variable "cluster_locations" {
  description = "Locations for the 3 Semaphore UI cluster servers (different zones)."
  type        = list(string)
  default     = ["fsn1", "nbg1", "hel1"]
}

variable "runner_locations" {
  description = "Locations for the 3 Semaphore runner servers."
  type        = list(string)
  default     = ["fsn1", "nbg1", "hel1"]
}

variable "network_zone" {
  description = "Private network zone (all locations above must belong to it)."
  type        = string
  default     = "eu-central"
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
