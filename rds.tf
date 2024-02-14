module "rds-aurora-db" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "~> 7.7.1"

  name           = "${var.env}-lh-aurora-mysql"
  engine         = "aurora-mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  instances = { one = {} }

  create_db_subnet_group = false
  create_security_group  = true

  deletion_protection     = var.env == "production"
  preferred_backup_window = "07:00-08:00"

  vpc_id               = module.vpc.vpc_id
  db_subnet_group_name = module.vpc.database_subnet_group_name
  subnets              = module.vpc.database_subnets

  // This allows me to connect via the bastion for workbench access
  // and allows applications running in the private subnets of my VPC to have access as well
  allowed_cidr_blocks = concat(
    ["${module.ec2-bastion.private_ip}/32"],
    module.vpc.private_subnets_cidr_blocks
  )

  iam_database_authentication_enabled = false
  master_password                     = random_password.rds_root_password.result
  master_username                     = "root"

  apply_immediately   = true
  skip_final_snapshot = var.env != "production"

  create_db_parameter_group      = true
  db_parameter_group_name        = "${var.env}-lh-aurora-mysql-parameter-group"
  db_parameter_group_family      = "aurora-mysql8.0"
  db_parameter_group_description = "${var.env}-lh-aurora-mysql example DB parameter group"
  db_parameter_group_parameters = [{
    name         = "connect_timeout"
    value        = 10
    apply_method = "immediate"
    }, {
    name         = "general_log"
    value        = 0
    apply_method = "immediate"
    }, {
    name         = "innodb_lock_wait_timeout"
    value        = 10
    apply_method = "immediate"
    }, {
    name         = "log_output"
    value        = "FILE"
    apply_method = "pending-reboot"
    }, {
    name         = "long_query_time"
    value        = 5
    apply_method = "immediate"
    }, {
    name         = "max_connections"
    value        = 200
    apply_method = "immediate"
    }, {
    name         = "slow_query_log"
    value        = 1
    apply_method = "immediate"
    }, {
    name         = "log_bin_trust_function_creators"
    value        = 1
    apply_method = "immediate"
  }]

  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  security_group_use_name_prefix  = false
}

resource "random_password" "rds_root_password" {
  length  = 25
  special = false
}
