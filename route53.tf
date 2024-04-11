resource "aws_route53_zone" "limit_handler" {
  name = "lh-${var.env}.com"

  vpc {
    vpc_id = module.vpc.vpc_id
  }
}

resource "aws_route53_record" "elasticache_endpoint" {
  zone_id = aws_route53_zone.limit_handler.zone_id
  name    = "elasticache-endpoint-${var.env}"
  type    = "CNAME"
  ttl     = 300

  records = [module.redis.endpoint]
}
