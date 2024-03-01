module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.4.0"

  identifier = "${var.env}-limit-handler-db"

  engine               = "mysql"
  major_engine_version = "8.0"
  engine_version       = "8.0.28"
  instance_class       = "db.t2.micro"
  allocated_storage    = 8

  vpc_security_group_ids = [aws_security_group.allow_lh_connections.id]

  db_name  = "limit_handler"
  username = "root"
  password = random_password.rds_root_password.result
  port     = 3306

  subnet_ids           = module.vpc.database_subnets
  parameter_group_name = "${var.env}-limit-handler-db-parameter-group"

  deletion_protection = var.env == "production"

  family = "mysql8.0"

  storage_encrypted = false
}

resource "aws_security_group" "allow_lh_connections" {
  name        = "${var.env}-allow-lh-connections"
  description = "Allows connections and queries from the limit handler api server"
  vpc_id      = module.vpc.vpc_id

  egress = {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = concat(module.vpc.public_subnets, module.vpc.private_subnets)
  }


}


resource "random_password" "rds_root_password" {
  length  = 25
  special = false
}
