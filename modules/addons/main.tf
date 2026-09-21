resource "aws_eks_addon" "this" {
  for_each = toset(var.addons)

  cluster_name = var.cluster_name
  addon_name   = each.value

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags
}