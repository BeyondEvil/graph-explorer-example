variable "aws_account_id" {
  description = "Account ID for the used by the provider"
  type        = string
}

variable "hosted_zone_name" {
  description = "The name of the public Route53 hosted zone"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets ID"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}
