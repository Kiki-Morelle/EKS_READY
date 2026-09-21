terraform {
  backend "s3" {
    bucket       = "terraform-sm-2026"
    key          = "eks-platform/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}