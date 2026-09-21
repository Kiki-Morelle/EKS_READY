output "cluster_name" {
  value = module.eks.cluster_name
}

output "efs_file_system_id" {
  value = module.efs.file_system_id
}
output "argocd_url" {
  value = "https://argocd.${var.domain_name}"
}

output "grafana_url" {
  value = "https://grafana.${var.domain_name}"
}

output "grafana_admin_password" {
  value     = module.monitoring.grafana_admin_password
  sensitive = true
}