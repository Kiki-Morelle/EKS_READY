module "vpc" {
  source = "../../modules/vpc"

  name                 = var.name
  cluster_name         = var.cluster_name
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  single_nat_gateway   = var.single_nat_gateway
}

module "eks" {
  source = "../../modules/eks-cluster"

  cluster_name         = var.cluster_name
  kubernetes_version   = var.kubernetes_version
  subnet_ids           = module.vpc.private_subnet_ids
  admin_principal_arns = var.admin_principal_arns
}

module "addons_core" {
  source = "../../modules/addons"

  cluster_name = module.eks.cluster_name
  addons       = ["vpc-cni", "kube-proxy", "eks-pod-identity-agent"]
}

module "node_group" {
  source = "../../modules/node-group"

  cluster_name   = module.eks.cluster_name
  subnet_ids     = module.vpc.private_subnet_ids
  instance_types = var.node_instance_types
  desired_size   = var.node_desired_size
  min_size       = var.node_min_size
  max_size       = var.node_max_size

  depends_on = [module.addons_core]
}

module "pi_ebs_csi" {
  source = "../../modules/pod-identity"

  cluster_name    = module.eks.cluster_name
  role_name       = "${var.cluster_name}-ebs-csi"
  namespace       = "kube-system"
  service_account = "ebs-csi-controller-sa"
  policy_arns     = ["arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"]
}

module "pi_efs_csi" {
  source = "../../modules/pod-identity"

  cluster_name    = module.eks.cluster_name
  role_name       = "${var.cluster_name}-efs-csi"
  namespace       = "kube-system"
  service_account = "efs-csi-controller-sa"
  policy_arns     = ["arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"]
}

module "efs" {
  source = "../../modules/efs"

  name                      = var.name
  vpc_id                    = module.vpc.vpc_id
  subnet_ids                = module.vpc.private_subnet_ids
  allowed_security_group_id = module.eks.cluster_security_group_id
}

module "addons_workload" {
  source = "../../modules/addons"

  cluster_name = module.eks.cluster_name
  addons       = ["coredns", "aws-ebs-csi-driver", "aws-efs-csi-driver"]

  depends_on = [
    module.node_group,
    module.pi_ebs_csi,
    module.pi_efs_csi,
  ]
}

module "alb_controller" {
  source = "../../modules/alb-controller"

  cluster_name = module.eks.cluster_name
  region       = var.region
  vpc_id       = module.vpc.vpc_id

  depends_on = [module.addons_workload]
}

module "argocd" {
  source = "../../modules/argocd"

  hostname             = "argocd.${var.domain_name}"
  certificate_arn      = aws_acm_certificate_validation.this.certificate_arn
  gitops_repo_url      = var.gitops_repo_url
  gitops_repo_revision = var.gitops_repo_revision
  gitops_repo_path     = var.gitops_repo_path

  depends_on = [
    module.alb_controller,
    helm_release.external_dns,
  ]
}

module "monitoring" {
  source = "../../modules/monitoring"

  grafana_hostname = "grafana.${var.domain_name}"
  certificate_arn  = aws_acm_certificate_validation.this.certificate_arn
  storage_class    = kubernetes_storage_class_v1.gp3.metadata[0].name

  depends_on = [
    module.alb_controller,
    helm_release.external_dns,
  ]
}