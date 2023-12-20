variable "aws_account_id" {
  description = "Account ID for the used by the provider"
  type        = string
}

variable "hosted_zone_name" {
  description = "The name of the private Route53 hosted zone"
  type        = string
}

variable "neptune_cluster_resource_id" {
  description = "Neptune Cluster resource ID"
  type        = string
}

variable "neptune_ro_endpoint" {
  description = "The read-only endpoint of the Neptune cluster"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets ID"
  type        = list(any)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs"
  type        = list(any)
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}
