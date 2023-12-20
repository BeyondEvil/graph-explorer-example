locals {
  cluster_name        = "neptune-cluster"
  engine_version      = "1.3.0.0"
  maintenance_window  = "fri:18:00-fri:19:00" # UTC
  neptune_port        = 8182
  paramter_group_name = "default.neptune1.3"

  neptune_allowed_sg = [
    var.ecs_security_group_id
  ]
}

resource "aws_neptune_subnet_group" "this" {
  name       = "${local.cluster_name}-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_neptune_cluster" "this" {
  cluster_identifier = local.cluster_name

  allow_major_version_upgrade          = false
  apply_immediately                    = true
  backup_retention_period              = 30
  copy_tags_to_snapshot                = true
  engine                               = "neptune"
  engine_version                       = local.engine_version
  final_snapshot_identifier            = "${local.cluster_name}-final"
  iam_database_authentication_enabled  = true
  neptune_cluster_parameter_group_name = local.paramter_group_name
  neptune_subnet_group_name            = aws_neptune_subnet_group.this.name
  port                                 = local.neptune_port
  preferred_backup_window              = "05:00-06:00" # UTC
  preferred_maintenance_window         = local.maintenance_window
  skip_final_snapshot                  = false
  storage_encrypted                    = true

  vpc_security_group_ids = [
    aws_security_group.this.id,
  ]
}

# Most values are inherited from the cluster.
resource "aws_neptune_cluster_instance" "this" {
  count = 1

  identifier = "${aws_neptune_cluster.this.id}-instance-${count.index + 1}"

  cluster_identifier           = aws_neptune_cluster.this.id
  instance_class               = "db.t3.medium"
  neptune_parameter_group_name = local.paramter_group_name
  preferred_maintenance_window = local.maintenance_window
}

resource "aws_security_group" "this" {
  name        = "NeptuneSecurityGroup"
  description = "Security group for Neptune"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = toset(local.neptune_allowed_sg)

  security_group_id = aws_security_group.this.id

  from_port   = local.neptune_port
  ip_protocol = "tcp"
  to_port     = local.neptune_port

  referenced_security_group_id = each.key
}

resource "aws_vpc_security_group_egress_rule" "this" {
  security_group_id = aws_security_group.this.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}
