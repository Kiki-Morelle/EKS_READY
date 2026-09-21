variable "cluster_name" {
  type = string
}

variable "role_name" {
  type = string
}

variable "namespace" {
  type = string
}

variable "service_account" {
  type = string
}

variable "policy_arns" {
  type    = list(string)
  default = []
}

variable "inline_policy" {
  description = "Optional custom policy JSON (used later for the ALB controller)."
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}