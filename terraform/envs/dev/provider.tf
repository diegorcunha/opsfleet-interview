terraform {
  required_version = ">= 1.3.0"

  backend "s3" {
    bucket         = "project-terraform-backend-dev"
    key            = "terraform/envs/dev/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "project-terraform-backend-dev"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}

provider "aws" {
  region = local.region
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "arn:aws:eks:${local.region}:${local.account_id}:cluster/${local.env}-cluster"
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "arn:aws:eks:${local.region}:${local.account_id}:cluster/${local.env}-cluster"
}
