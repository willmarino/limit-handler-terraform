module "vpc" {
    source  = "terraform-aws-modules/vpc/aws"
    version = "~> 5.0"

    name = "lh-${var.env}-vpc-${random_pet.vpc_name.id}"
    cidr = var.vpc_cidr_block

    enable_dns_support   = true // support setting up vpn-scoped dns names
    enable_dns_hostnames = true // specifically enables hostnames, works with enable_dns_support

    # Allow outbound internet from public and private subnets
    create_igw             = true // for public subnets
    create_egress_only_igw = true // for private subnets

    # Create subnets for and routing for RDS
    create_database_subnet_group       = true
    create_database_subnet_route_table = true

    create_database_nat_gateway_route      = false # No internet access to the database subnets
    create_database_internet_gateway_route = false # No public database access should be created

    azs              = ["${var.region}a"]
    public_subnets   = ["10.20.0.0/24"]
    private_subnets  = ["10.20.3.0/24"]
    database_subnets = ["10.20.7.0/24"]

    enable_nat_gateway     = true
    single_nat_gateway     = false
    one_nat_gateway_per_az = true

    manage_default_security_group = false
    manage_default_route_table    = false
    manage_default_network_acl    = false
}

resource "random_pet" "vpc_name" {}
