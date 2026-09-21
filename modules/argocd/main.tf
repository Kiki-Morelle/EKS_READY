resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version

  values = [yamlencode({
    global = {
      domain = var.hostname
    }

    configs = {
      params = {
        "server.insecure" = true
      }
    }

    dex = {
      enabled = false
    }

    server = {
      ingress = {
        enabled          = true
        ingressClassName = "alb"
        hostname         = var.hostname

        annotations = {
          "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
          "alb.ingress.kubernetes.io/target-type"      = "ip"
          "alb.ingress.kubernetes.io/group.name"       = "platform"
          "alb.ingress.kubernetes.io/listen-ports"     = jsonencode([{ HTTP = 80 }, { HTTPS = 443 }])
          "alb.ingress.kubernetes.io/ssl-redirect"     = "443"
          "alb.ingress.kubernetes.io/certificate-arn"  = var.certificate_arn
          "alb.ingress.kubernetes.io/backend-protocol" = "HTTP"
          "alb.ingress.kubernetes.io/healthcheck-path" = "/healthz"
        }
      }
    }
  })]
}

# ---------- Optional: connect Argo CD to your Git repo (app-of-apps) ----------
resource "helm_release" "apps" {
  count = var.gitops_repo_url == null ? 0 : 1

  name       = "argocd-apps"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"

  values = [yamlencode({
    applications = {
      root = {
        namespace = "argocd"
        project   = "default"

        source = {
          repoURL        = var.gitops_repo_url
          targetRevision = var.gitops_repo_revision
          path           = var.gitops_repo_path
          directory      = { recurse = true }
        }

        destination = {
          server    = "https://kubernetes.default.svc"
          namespace = "argocd"
        }

        syncPolicy = {
          automated = {
            prune    = true
            selfHeal = true
          }
        }
      }
    }
  })]

  depends_on = [helm_release.argocd]
}