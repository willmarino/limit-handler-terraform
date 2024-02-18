module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.4.0"

  identifier = "${var.env}-limit-handler-db"

  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t2.micro"
  allocated_storage = 2

  db_name  = "limit_handler"
  username = "root"
  password = random_password.rds_root_password.result
  port     = 3306

  subnet_ids           = module.vpc.database_subnets
  parameter_group_name = "${var.env}-limit-handler-db-parameter-group"

  deletion_protection = var.env == "production"

}


resource "random_password" "rds_root_password" {
  length  = 25
  special = false
}
