variable "cluster_name" {
  type = string
}

variable "addons" {
  type = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}