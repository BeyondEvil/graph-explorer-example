resource "aws_s3_bucket" "alb_logs" {
  bucket = "GraphExplorerALBAccessLogs"
}

resource "aws_s3_bucket_ownership_controls" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  acl    = "private"

  depends_on = [
    aws_s3_bucket_ownership_controls.alb_logs
  ]
}

data "aws_iam_policy_document" "alb_logs" {
  statement {
    sid       = "AllowALBPutLogs"
    actions   = ["s3:PutObject"]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.alb_logs.arn}/*"]

    principals {
      type = "AWS"
      identifiers = [
        data.aws_elb_service_account.default.arn
      ]
    }
  }

  statement {
    sid     = "AllowSSLRequestsOnly"
    actions = ["s3:*"]
    effect  = "Deny"
    resources = [
      aws_s3_bucket.alb_logs.arn,
      "${aws_s3_bucket.alb_logs.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  policy = data.aws_iam_policy_document.alb_logs.json
}
