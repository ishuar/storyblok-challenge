# https://github.com/terraform-aws-modules/terraform-aws-vpc/tree/v5.21.0

data "aws_availability_zones" "available" {}

locals {
  name                  = var.vpc_name
  vpc_cidr              = var.vpc_cidr
  secondary_cidr_blocks = var.vpc_secondary_cidr_blocks
  azs                   = slice(data.aws_availability_zones.available.names, 0, 3)
  s3_bucket_name        = "vpc-flow-logs-to-s3-${random_pet.this.id}"
}

resource "random_pet" "this" {
  length = 3
}

####################
## VPC
####################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name                  = local.name
  cidr                  = local.vpc_cidr
  azs                   = local.azs
  secondary_cidr_blocks = local.secondary_cidr_blocks

  ## subnets
  ## ref: https://docs.aws.amazon.com/eks/latest/best-practices/subnets.html
  private_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  public_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 4)]
  database_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 12)]

  ## private subnets that have no Internet routing
  intra_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 8)]

  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_ipv6          = true

  ## NAT Gateway
  enable_nat_gateway     = true
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  ## VPC Flow Logs
  enable_flow_log                   = true
  flow_log_destination_arn          = module.s3_bucket.s3_bucket_arn
  flow_log_destination_type         = "s3"
  flow_log_max_aggregation_interval = "600"
  flow_log_traffic_type             = "ALL"
  flow_log_file_format              = "parquet"
  vpc_flow_log_tags                 = var.tags


  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
  intra_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
  tags = var.tags
}

####################
## VPC Flow Logs
####################

# S3 Bucket
module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.9.0"

  bucket        = local.s3_bucket_name
  policy        = data.aws_iam_policy_document.flow_log_s3.json
  force_destroy = true

  tags = var.tags
}

data "aws_iam_policy_document" "flow_log_s3" {
  statement {
    sid = "AWSLogDeliveryWrite"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = ["arn:aws:s3:::${local.s3_bucket_name}/AWSLogs/*"]
  }

  statement {
    sid = "AWSLogDeliveryAclCheck"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = ["s3:GetBucketAcl"]

    resources = ["arn:aws:s3:::${local.s3_bucket_name}"]
  }
}
