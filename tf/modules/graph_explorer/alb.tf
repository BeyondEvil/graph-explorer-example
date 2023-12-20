locals {
  http_port  = 80
  https_port = 443
}

resource "aws_security_group" "alb" {
  name        = "GraphExplorerALBSecurityGroup"
  description = "Security group for the ALB"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = local.https_port
  ip_protocol = "tcp"
  to_port     = local.https_port
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = local.http_port
  ip_protocol = "tcp"
  to_port     = local.http_port
}

resource "aws_vpc_security_group_egress_rule" "outbound" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_lb" "this" {
  name               = "GraphExplorerALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    prefix  = "graph-explorer"
    enabled = true
  }
}

resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.this.arn
  port              = local.http_port
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = local.https_port
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# This will likely fail to create on the first apply.
# The reason is that the certificate validation takes some time.
# Once validation has passed (check the AWS console) a rerun should be successful.
resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.id
  port              = local.https_port
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    target_group_arn = aws_lb_target_group.this.arn
    type             = "forward"
  }

  certificate_arn = aws_acm_certificate.this.arn
}

# This rule handles the case where the Graph Explorer UI
# tries to connect to Neptune using the proxy
resource "aws_lb_listener_rule" "root_path_forward" {
  listener_arn = aws_lb_listener.this.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }

  condition {
    http_header {
      http_header_name = "graph-db-connection-url"
      values           = ["*neptune*"]
    }
  }
}

# This handles "first load" when hitting the DNS name
# so that the user doesn't get the "invalid url", which
# comes from the proxy (see rule with priority = 1)
resource "aws_lb_listener_rule" "root_path_redirect" {
  listener_arn = aws_lb_listener.this.arn
  priority     = 999

  action {
    type = "redirect"

    redirect {
      path        = "/explorer"
      status_code = "HTTP_301"
    }
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/5.26.0/docs/resources/lb_target_group
resource "aws_lb_target_group" "this" {
  name        = "GraphExplorerALBTargetGroup"
  port        = local.https_port
  protocol    = "HTTPS"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    healthy_threshold   = "3"
    interval            = "90"
    protocol            = "HTTPS"
    matcher             = "200"
    timeout             = "20"
    path                = "/explorer/#/connections" # There really should exist a /status or /health endpoint
    unhealthy_threshold = "2"
  }
}

resource "aws_route53_record" "alb" {
  zone_id = data.aws_route53_zone.public_hosted_zone.id
  name    = "graph-explorer.${var.hosted_zone_name}"
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = false
  }
}

resource "aws_acm_certificate" "this" {
  domain_name       = aws_route53_record.alb.name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
      zone_id = data.aws_route53_zone.public_hosted_zone.id
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone_id
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
