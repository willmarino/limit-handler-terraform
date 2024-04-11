resource "aws_route53_zone" "private_internal" {
  name = "lh-${var.env}.com"

  vpc {
    vpc_id = module.vpc.vpc_id
  }
}

resource "aws_route53_record" "elasticache_primary_node_proxyname" {
  zone_id = aws_route53_zone.private_internal.zone_id
  name    = "elasticache-endpoint-${var.env}"
  type    = "CNAME"
  ttl     = 300

  records = [module.redis.endpoint]
}
