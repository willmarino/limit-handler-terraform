resource "aws_acm_certificate" "cf_origin" {
  private_key      = var.cf_origin_cert_private_key
  certificate_body = var.cf_origin_cert_body
}
