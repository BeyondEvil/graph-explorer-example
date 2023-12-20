
module "neptune" {
  source = "../modules/neptune"

  ecs_security_group_id = module.graph_explorer.ecs_security_group_id
  private_subnet_ids    = var.private_subnet_ids
  vpc_id                = var.vpc_id
}

module "graph_explorer" {
  source = "../modules/graph_explorer"

  aws_account_id              = var.aws_account_id
  hosted_zone_name            = var.hosted_zone_name
  vpc_id                      = var.vpc_id
  neptune_cluster_resource_id = module.neptune.cluster_resource_id
  neptune_ro_endpoint         = module.neptune.ro_endpoint
  private_subnet_ids          = var.private_subnet_ids
  public_subnet_ids           = var.public_subnet_ids
}
