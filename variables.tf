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

variable "limit-handler-name" {
  description = "limit-handler name"
  type        = string
  default     = "limit-handler"
}


variable "datadog_api_key" {
  description = "datadog api key"
  type        = string
}

variable "cf_origin_cert_body" {
  description = "cloudflare origin cert body"
}

variable "cf_origin_cert_private_key" {
  description = "cloudflare origin cert private key"
}
