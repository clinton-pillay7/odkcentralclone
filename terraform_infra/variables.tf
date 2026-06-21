variable "sysadmin_email" {
  type        = string
  description = "The primary administrator email address for ODK Central."
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.sysadmin_email))
    error_message = "The sysadmin_email value must be a valid email address."
  }
}

variable "duckdns_token" {
  description = "Your DuckDNS token"
  type        = string
  sensitive   = true
  default     = "8a4f1104-a68d-43c1-ba32-d4ba77b2e93b"
}

variable "duckdns_domain" {
  description = "Your subdomain"
  type        = string
}

variable "prometheus_pass" {
  description = "Enter password for Prometheus"
  type        = string
}

variable "grafana_pass" {
  description = "Grafana admin password"
  sensitive   = true
}
