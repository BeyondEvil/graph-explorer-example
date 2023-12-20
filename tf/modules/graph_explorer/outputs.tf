output "ecs_security_group_id" {
  value       = aws_security_group.ecs.id
  sensitive   = false
  description = "ID of the ECS security group"
}
