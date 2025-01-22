module "vpc" {
  source       = "../../modules/vpc"
  vpc_cidr     = local.vpc_cidr
  environment  = local.env
  name         = local.name
  azs          = local.azs
  cluster_name = local.cluster_name
  tags = {
    Owner                    = "DevOps Team"
    Project                  = "Example"
    "karpenter.sh/discovery" = local.cluster_name
  }
}

module "eks" {
  source                      = "../../modules/eks"
  cluster_name                = local.cluster_name
  vpc_id                      = module.vpc.vpc_id
  aws_region                  = local.region
  private_subnets             = module.vpc.private_subnets
  public_subnets              = module.vpc.public_subnets
  k8s_version                 = local.k8s_version
  name_prefix                 = local.name
  eks_node_groups             = local.eks_node_groups
  account_name                = local.account_id
  environment                 = local.env
  tags = {
    Owner                    = "DevOps Team"
    Project                  = "Example"
    "karpenter.sh/discovery" = local.cluster_name
  }
}
