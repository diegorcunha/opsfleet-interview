module "vpc" {
  source      = "../../modules/vpc"
  vpc_cidr    = local.vpc_cidr
  environment = local.env
  tags = {
    Owner = "DevOps Team"
    Project = "Example"
  }
}
