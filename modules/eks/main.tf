module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name    = var.cluster_name
  cluster_version = "1.30"

  vpc_id                                   = var.vpc_id
  subnet_ids                               = var.private_subnets
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true
  cluster_addons = {
    coredns = {
      configuration_values = jsonencode({
        tolerations = [
          # Allow CoreDNS to run on the same nodes as the Karpenter controller
          # for use during cluster creation when Karpenter nodes do not yet exist
          {
            key    = "karpenter.sh/controller"
            value  = "true"
            effect = "NoSchedule"
          }
        ]
      })
    }
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }


  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    karpenter_manager = {
      name = "karpenter_manager"

      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 3
      desired_size = 1
      labels = {
        # Used to ensure Karpenter runs on nodes that it does not manage
        "karpenter.sh/controller" = "true"
      }

      taints = {
        # The pods that do not tolerate this taint should run on nodes
        # created by Karpenter
        karpenter = {
          key    = "karpenter.sh/controller"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  node_security_group_tags = merge(var.tags, {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = var.cluster_name
  })

  tags = var.tags
}


output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}"
}

# resource "helm_release" "nvidia_device_plugin" {
#   name       = "nvidia-device-plugin"
#   namespace  = "kube-system"
#   chart      = "nvidia-device-plugin"
#   repository = "https://nvidia.github.io/k8s-device-plugin"
#   version    = "0.14.1" # Use the latest compatible version

#   values = [
#     <<EOF
# # Customizable Helm values for the NVIDIA Device Plugin
# resources:
#   limits:
#     nvidia.com/gpu: 1
#   requests:
#     nvidia.com/gpu: 1
# plugin:
#   env:
#     - name: "NVIDIA_VISIBLE_DEVICES"
#       value: "all"
#     - name: "NVIDIA_DRIVER_CAPABILITIES"
#       value: "utility,compute"
# EOF
#   ]
