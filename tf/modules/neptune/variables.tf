variable "ecs_security_group_id" {
  description = "ID of the ECS security group"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets ID"
  type        = list(any)
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}
