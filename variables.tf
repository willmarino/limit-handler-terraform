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
  type        = string
  default     = "us-east-1"
}

variable "bastion_public_key_staging" {
  description = "Bastion host public key"
  type        = string
}

variable "a" {
  description = "b"
  type        = string
}
