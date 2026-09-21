variable "region" {
  type = string
}

variable "name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "single_nat_gateway" {
  type    = bool
  default = true
}

variable "kubernetes_version" {
  type = string
}

variable "admin_principal_arns" {
  type    = list(string)
  default = []
}

variable "node_instance_types" {
  type = list(string)
}

variable "node_desired_size" {
  type = number
}

variable "node_min_size" {
  type = number
}

variable "node_max_size" {
  type = number
}

variable "domain_name" {
  type = string
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