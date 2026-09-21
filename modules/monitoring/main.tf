resource "random_password" "grafana" {
  length  = 24
  special = false
}

resource "helm_release" "this" {
  name             = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = var.chart_version
  timeout          = 900

  set_sensitive = [
    { name = "grafana.adminPassword", value = random_password.grafana.result }
  ]

  values = [yamlencode({
    # EKS control plane is managed by AWS, so these targets can't be scraped
    kubeEtcd              = { enabled = false }
    kubeControllerManager = { enabled = false }
    kubeScheduler         = { enabled = false }
    kubeProxy             = { enabled = false }

    prometheus = {
      prometheusSpec = {
        retention = var.prometheus_retention

        # Pick up ServiceMonitors/PodMonitors from ANY namespace (your app's metrics)
        serviceMonitorSelectorNilUsesHelmValues = false
        podMonitorSelectorNilUsesHelmValues     = false

        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              storageClassName = var.storage_class
              accessModes      = ["ReadWriteOnce"]
              resources = {
                requests = { storage = var.prometheus_storage_size }
              }
            }
          }
        }
      }
    }

    grafana = {
      persistence = {
        enabled          = true
        storageClassName = var.storage_class
        size             = "10Gi"
      }

      "grafana.ini" = {
        server = {
          domain   = var.grafana_hostname
          root_url = "https://${var.grafana_hostname}"
        }
      }

      ingress = {
        enabled          = true
        ingressClassName = "alb"
        hosts            = [var.grafana_hostname]

        annotations = {
          "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
          "alb.ingress.kubernetes.io/target-type"     = "ip"
          "alb.ingress.kubernetes.io/group.name"      = "platform"
          "alb.ingress.kubernetes.io/listen-ports"    = jsonencode([{ HTTP = 80 }, { HTTPS = 443 }])
          "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
          "alb.ingress.kubernetes.io/certificate-arn" = var.certificate_arn
          "alb.ingress.kubernetes.io/healthcheck-path" = "/api/health"
        }
      }
    }
  })]
}