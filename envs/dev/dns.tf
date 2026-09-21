# ---------- Existing Route 53 zone ----------
data "aws_route53_zone" "this" {
  name         = var.domain_name
  private_zone = false
}

# ---------- ACM certificate (apex + wildcard) ----------
resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => dvo
  }

  allow_overwrite = true
  zone_id         = data.aws_route53_zone.this.zone_id
  name            = each.value.resource_record_name
  type            = each.value.resource_record_type
  records         = [each.value.resource_record_value]
  ttl             = 60
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

# ---------- ExternalDNS ----------
module "pi_external_dns" {
  source = "../../modules/pod-identity"

  cluster_name    = module.eks.cluster_name
  role_name       = "${var.cluster_name}-external-dns"
  namespace       = "external-dns"
  service_account = "external-dns"

  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["route53:ChangeResourceRecordSets"]
        Resource = ["arn:aws:route53:::hostedzone/${data.aws_route53_zone.this.zone_id}"]
      },
      {
        Effect   = "Allow"
        Action   = ["route53:ListHostedZones", "route53:ListResourceRecordSets", "route53:ListTagsForResource"]
        Resource = ["*"]
      }
    ]
  })
}

resource "helm_release" "external_dns" {
  name             = "external-dns"
  namespace        = "external-dns"
  create_namespace = true
  repository       = "https://kubernetes-sigs.github.io/external-dns/"
  chart            = "external-dns"

  set = [
    { name = "provider.name", value = "aws" },
    { name = "sources[0]", value = "ingress" },
    { name = "sources[1]", value = "service" },
    { name = "domainFilters[0]", value = var.domain_name },
    { name = "policy", value = "sync" },
    { name = "txtOwnerId", value = var.cluster_name },
    { name = "serviceAccount.create", value = "true" },
    { name = "serviceAccount.name", value = "external-dns" },
    { name = "env[0].name", value = "AWS_DEFAULT_REGION" },
    { name = "env[0].value", value = var.region },
  ]

  depends_on = [
    module.pi_external_dns,
    module.addons_workload,
  ]
}