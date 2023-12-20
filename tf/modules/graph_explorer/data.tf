data "aws_region" "current" {}

data "aws_elb_service_account" "default" {}

data "aws_route53_zone" "public_hosted_zone" {
  name         = "${var.hosted_zone_name}."
  private_zone = false
}
