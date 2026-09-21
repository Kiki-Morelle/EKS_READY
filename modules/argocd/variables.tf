variable "hostname" {
  description = "Public hostname, e.g. argocd.example.com"
  type        = string
}

variable "certificate_arn" {
  type = string
}

variable "chart_version" {
  description = "null = latest. Pin it once you know the version that works."
  type        = string
  default     = null
}

variable "gitops_repo_url" {
  description = "Git repo Argo CD watches. null = install Argo CD without connecting a repo."
  type        = string
  default     = null
}

variable "gitops_repo_revision" {
  type    = string
  default = "main"
}

variable "gitops_repo_path" {
  type    = string
  default = "apps"
}