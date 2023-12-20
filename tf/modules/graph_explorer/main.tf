locals {
  container_name = "graph-explorer"
  container_port = 80
}

resource "aws_security_group" "ecs" {
  name        = "GraphExplorerECSSecurityGroup"
  description = "Security group for the ECS"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb" {
  security_group_id = aws_security_group.ecs.id

  from_port   = local.https_port
  ip_protocol = "tcp"
  to_port     = local.https_port

  referenced_security_group_id = aws_security_group.alb.id
}

# Likely not needed since we redirect 80 -> 443 at the ALB
resource "aws_vpc_security_group_ingress_rule" "local" {
  security_group_id = aws_security_group.ecs.id

  from_port   = local.container_port
  ip_protocol = "tcp"
  to_port     = local.container_port

  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_egress" {
  security_group_id = aws_security_group.ecs.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_cloudwatch_log_group" "ecs" {
  name = "GraphExplorerECSLogGroup"
}

resource "aws_ecs_cluster" "this" {
  name = "GraphExplorerECSCluster"
}

resource "aws_ecs_task_definition" "this" {
  family             = "GraphExplorerECSTaskFamily"
  network_mode       = "awsvpc"
  execution_role_arn = data.aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.neptune_task_role.arn
  cpu                = 1024
  memory             = 2048

  container_definitions = templatefile("${path.module}/templates/task_definition.json.tftpl", {
    alb_fqdn            = aws_route53_record.alb.fqdn
    app_name            = local.container_name
    container_port      = local.container_port
    https_port          = local.https_port
    image_tag           = "1.4.0"
    log_group           = aws_cloudwatch_log_group.ecs.name
    neptune_ro_endpoint = var.neptune_ro_endpoint
    region              = data.aws_region.current.name
  })

  requires_compatibilities = [
    "FARGATE"
  ]
}

resource "aws_ecs_service" "this" {
  name            = "GraphExplorerECSService"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    container_name   = local.container_name
    container_port   = local.https_port
    target_group_arn = aws_lb_target_group.this.arn
  }
}
