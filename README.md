# AWS Neptune and Graph Explorer

Example repo that sets up a single-instance Neptune Cluster and deploys the Graph Explorer on ECS Fargate.

[AWS Neptune User Guide](https://docs.aws.amazon.com/neptune/latest/userguide/intro.html)

[Graph Explorer Github](https://github.com/aws/graph-explorer)

## Prerequisites

- A VPC with subnets incl. proper IG and NAT:ing (out of scope for this).
- A public Hosted Zone (Route53) for DNS to work.

It's also expected that you understand the fundamentals of how to work with Terraform.

I've tried to make the example as complete as possible. With that said I welcome PRs with improvements etc.

## Notes

- The ingress rules opens up the Graph Explorer to the world. This is probably not what you want since Graph Explorer doesn't provide any mechanisms for authentication or authorization.
- It's a good idea to initially comment out the `aws_lb_listener_rule`'s and make sure everything is working first.
- The graph type is hardcoded to "opencypher" in the task definition.
