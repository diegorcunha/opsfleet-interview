variable "account_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "name_prefix" {
  type        = string
  description = "A unique prefix to idenitfy this cluster and prevent naming collisions."
}

variable "eks_node_groups" {
  type = map(any)
}

variable "private_subnets" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.27"
}

variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
}

variable "system_namespace" {
  default = "kube-system"
}

variable "environment" {
  description = "Environment (dev, stage, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
