
variable "env" {
    description = "The environment name"
}

variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.20.0.0/18"
}

variable "region" {
  description = "Primary AWS region"
  default     = "us-east-1"
}
