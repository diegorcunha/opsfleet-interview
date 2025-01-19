terraform {
  required_version = ">= 1.3.0"

  backend "s3" {
    bucket         = "project-terraform-backend-dev"
    key            = "eks-karpenter/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "project-terraform-backend-dev"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = local.region
}
