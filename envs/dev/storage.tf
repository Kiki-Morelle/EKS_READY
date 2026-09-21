# ---------- EBS (single-pod disks: Prometheus, Grafana) ----------
resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type      = "gp3"
    encrypted = "true"
  }

  depends_on = [module.addons_workload]
}

# ---------- EFS (shared files: ReadWriteMany across pods) ----------
resource "kubernetes_storage_class_v1" "efs" {
  metadata {
    name = "efs"
  }

  storage_provisioner = "efs.csi.aws.com"
  reclaim_policy      = "Delete"
  volume_binding_mode = "Immediate"

  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId     = module.efs.file_system_id
    directoryPerms   = "700"
    basePath         = "/dynamic"
  }

  depends_on = [module.addons_workload]
}