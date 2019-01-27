variable "domain" {
  default = "master"
}

resource "aws_elasticsearch_domain" "master" {
  domain_name           = "master"
  elasticsearch_version = "6.4"

  cluster_config {
    instance_type = "t2.micro.elasticsearch"
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  tags = {
    Domain = "TestDomain"
  }

  access_policies = <<POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": "*"
        },
        "Action": "es:*",
        "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.domain}/*"
      }
    ]
  }
  POLICY

  log_publishing_options {
    cloudwatch_log_group_arn = "${aws_cloudwatch_log_group.master-log.arn}"
    log_type                 = "INDEX_SLOW_LOGS"
  }
}



data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_cloudwatch_log_group" "master-log" {
  name = "master-log"
}

resource "aws_cloudwatch_log_resource_policy" "master-log" {
  policy_name = "master-log"

  policy_document = <<CONFIG
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "es.amazonaws.com"
      },
      "Action": [
        "logs:PutLogEvents",
        "logs:PutLogEventsBatch",
        "logs:CreateLogStream"
      ],
      "Resource": "arn:aws:logs:*"
    }
  ]
}
CONFIG
}
