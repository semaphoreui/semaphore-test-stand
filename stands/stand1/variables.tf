variable "api_base_url" {
  description = "Semaphore API base URL (or set SEMAPHOREUI_API_BASE_URL)."
  type        = string
  default     = "http://localhost:3000/api"
}

variable "api_token" {
  description = "Semaphore API token (or set SEMAPHOREUI_API_TOKEN)."
  type        = string
  sensitive   = true
}
