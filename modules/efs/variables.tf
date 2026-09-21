variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "allowed_security_group_id" {
  description = "Security group allowed to mount EFS (the EKS cluster security group)."
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}