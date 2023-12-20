output "cluster_resource_id" {
  value       = aws_neptune_cluster.this.cluster_resource_id
  sensitive   = false
  description = "The Neptune Cluster resource ID"
}

output "ro_endpoint" {
  value       = "https://${aws_neptune_cluster.this.reader_endpoint}:${local.neptune_port}"
  sensitive   = false
  description = "The read-only endpoint of the Neptune cluster. Including protocol and port."
}
