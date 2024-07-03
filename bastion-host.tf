# resource "aws_key_pair" "bastion" {
#   key_name   = "bastion-key"
#   public_key = var.bastion_public_key_staging
# }

# module "ec2-bastion" {
#   source  = "cloudposse/ec2-bastion-server/aws"
#   version = "~> 0.30.1"
#   ami     = "ami-0f0a8b9bc31bd649b"

#   environment = var.env

#   vpc_id        = module.vpc.vpc_id
#   subnets       = module.vpc.public_subnets
#   instance_type = "t2.micro"

#   key_name                    = aws_key_pair.bastion.key_name
#   ssm_enabled                 = true
#   assign_eip_address          = true
#   associate_public_ip_address = true
# }
