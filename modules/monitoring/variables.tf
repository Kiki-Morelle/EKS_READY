variable "grafana_hostname" {
  description = "Public hostname, e.g. grafana.example.com"
  type        = string
}

variable "certificate_arn" {
  type = string
}

variable "storage_class" {
  type = string
}

variable "prometheus_storage_size" {
  type    = string
  default = "30Gi"
}

variable "prometheus_retention" {
  type    = string
  default = "15d"
}

variable "chart_version" {
  description = "null = latest. Pin it once you know the version that works."
  type        = string
  default     = null
}