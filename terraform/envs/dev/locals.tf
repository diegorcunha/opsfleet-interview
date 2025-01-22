
data "aws_availability_zones" "available" {
  # Exclude local zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}
data "aws_caller_identity" "current" {}
locals {
  vpc_cidr     = "10.0.0.0/16"
  env          = "dev"
  region       = "us-east-2"
  cluster_name = "dev-cluster"
  k8s_version  = "1.31"
  azs          = slice(data.aws_availability_zones.available.names, 0, 3)
  name         = "${local.env}-test"
  account_id   = data.aws_caller_identity.current.account_id
  eks_node_groups = {
    "karpenter" = {
      instance_types = ["t3.medium"]
      ami_type       = "AL2_x86_64"
      disk_size      = 100
      desired_size   = 1
      max_size       = 10
      min_size       = 1
    }
  }
}

