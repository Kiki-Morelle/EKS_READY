variable "cluster_name" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "chart_version" {
  description = "null = latest. Pin it once you know the version that works."
  type        = string
  default     = null
}