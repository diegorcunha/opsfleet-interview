variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "environment" {
  description = "Environment (dev, stage, prod)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "azs" {
  description = "Availability Zones"
  type        = list(string)
}

variable "name" {
  description = "Project Name"
  type        = string
}

variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
}
