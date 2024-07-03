# module "redis" {
#   source  = "cloudposse/elasticache-redis/aws"
#   version = "~> 0.51.1"

#   environment                = var.env
#   vpc_id                     = module.vpc.vpc_id
#   availability_zones         = ["us-east-1a", "us-east-1b"]
#   allowed_security_group_ids = [aws_security_group.limit_handler_web.id, aws_security_group.limit_handler_req_util.id]
#   subnets                    = module.vpc.database_subnets
#   cluster_size               = 1
#   instance_type              = "cache.t2.micro"
#   automatic_failover_enabled = false
#   engine_version             = "6.2"
#   family                     = "redis6.x"
#   at_rest_encryption_enabled = false
#   transit_encryption_enabled = false

# }
