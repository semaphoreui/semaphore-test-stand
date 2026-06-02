variable "gcp_project" {
  description = "Google Cloud project ID that hosts all resources."
  type        = string
}

variable "prefix" {
  description = "Name prefix applied to every resource. Must match the server stack's prefix (used to look up its VPC/subnet)."
  type        = string
  default     = "semaphore"
}

variable "ssh_public_key" {
  description = "SSH public key contents granted access to every instance."
  type        = string
}

variable "ssh_user" {
  description = "Linux user the SSH public key is registered for (instance metadata `ssh-keys`)."
  type        = string
  default     = "ubuntu"
}

variable "machine_type" {
  description = "Compute Engine machine type used for all runner instances."
  type        = string
  default     = "e2-small"
}

variable "image" {
  description = "Boot disk image for all instances."
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
}

variable "region" {
  description = "Google Cloud region (must match the server stack's region)."
  type        = string
  default     = "europe-west3"
}

variable "zone" {
  description = "Compute Engine zone for runner instances (must be inside var.region)."
  type        = string
  default     = "europe-west3-a"
}

variable "web_root" {
  description = "Semaphore web root / API base host (e.g. https://lb.stand2.semaphoreui.dev)."
  type        = string
  default     = "https://localhost:3000"
}

variable "semaphore_version" {
  description = "Semaphore runner version (or set SEMAPHORE_RUNNER_VERSION)."
  type        = string
  default     = "2.18.6-beta5"
}

variable "api_token" {
  description = "Semaphore API token (or set SEMAPHOREUI_API_TOKEN)."
  type        = string
  sensitive   = true
}
