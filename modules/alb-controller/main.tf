module "pod_identity" {
  source = "../pod-identity"

  cluster_name    = var.cluster_name
  role_name       = "${var.cluster_name}-alb-controller"
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  inline_policy   = file("${path.module}/iam_policy.json")
}

resource "helm_release" "this" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.chart_version

  set = [
    { name = "clusterName", value = var.cluster_name },
    { name = "region", value = var.region },
    { name = "vpcId", value = var.vpc_id },
    { name = "serviceAccount.create", value = "true" },
    { name = "serviceAccount.name", value = "aws-load-balancer-controller" },
    { name = "replicaCount", value = "2" },
  ]

  depends_on = [module.pod_identity]
}