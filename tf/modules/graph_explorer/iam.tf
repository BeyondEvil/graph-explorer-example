data "aws_iam_role" "ecs_task_execution_role" {
  # this is a managed role, but doesn't always exist
  # see: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
  name = "ecsTaskExecutionRole"
}

resource "aws_iam_role" "neptune_task_role" {
  name               = "neptune-task-role"
  assume_role_policy = data.aws_iam_policy_document.neptune_task_role.json
}

data "aws_iam_policy_document" "neptune_task_role" {
  version = "2012-10-17"
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "neptune_read_access" {
  statement {
    effect = "Allow"

    actions = [
      "neptune-db:Get*",
      "neptune-db:List*",
      "neptune-db:Read*",
    ]

    resources = [
      "arn:aws:neptune-db:${data.aws_region.current.name}:${var.aws_account_id}:${var.neptune_cluster_resource_id}/*"
    ]
  }
}

resource "aws_iam_role_policy" "neptune_read_access" {
  name   = "NeptuneReadAccessPolicy"
  role   = aws_iam_role.neptune_task_role.id
  policy = data.aws_iam_policy_document.neptune_read_access.json
}
