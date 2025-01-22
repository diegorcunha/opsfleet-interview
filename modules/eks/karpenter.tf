terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0" # Use the latest compatible version
    }
  }
}

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.24"

  cluster_name          = module.eks.cluster_name
  enable_v1_permissions = true
  namespace             = "karpenter"

  # Name needs to match role name passed to the EC2NodeClass
  node_iam_role_use_name_prefix = false
  node_iam_role_name            = var.cluster_name

  # EKS Fargate does not support pod identity
  create_pod_identity_association = false
  enable_irsa                     = true
  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn

}

################################################################################
# Helm charts
################################################################################

resource "helm_release" "karpenter" {
  name             = "karpenter"
  namespace        = "karpenter"
  create_namespace = true
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = "1.0.2"
  wait             = false

  values = [
    <<-EOT
    nodeSelector:
      karpenter.sh/controller: 'true'
    dnsPolicy: Default
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: ${module.karpenter.iam_role_arn}
    tolerations:
      - key: CriticalAddonsOnly
        operator: Exists
      - key: karpenter.sh/controller
        operator: Exists
        effect: NoSchedule
    webhook:
      enabled: false
    EOT
  ]

  lifecycle {
    ignore_changes = [
      repository_password
    ]
  }
}

resource "kubectl_manifest" "karpenter_node_class_x86" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: x86
    spec:
      amiFamily: AL2
      role: "${module.karpenter.node_iam_role_name}"
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      amiSelectorTerms:
        - id: "ami-0113ae93759fd1462"
        - id: "ami-017f064013f68e6c9"
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_node_pool_x86" {
  provider  = kubectl
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: x86
    spec:
      template:
        spec:
          taints:
            - key: role
              value: x86
              effect: NoSchedule
          requirements:
            - key: kubernetes.io/os
              operator: In
              values: ["linux"]
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["spot"]
            - key: "karpenter.k8s.aws/instance-size"
              operator: In
              values: ["medium"]
            - key: "kubernetes.io/arch"
              operator: In
              values: ["amd64"]
          nodeClassRef:
            group: karpenter.k8s.aws
            kind: EC2NodeClass
            name: x86
          expireAfter: 720h
      disruption:
        consolidationPolicy: WhenEmpty
        consolidateAfter: 30s
        expireAfter: 720h

  YAML

  depends_on = [
    kubectl_manifest.karpenter_node_class_x86
  ]
}

resource "kubectl_manifest" "karpenter_node_class_arm64" {
  provider  = kubectl
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: arm64
    spec:
      amiFamily: AL2
      role: "${module.karpenter.node_iam_role_name}"
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      amiSelectorTerms:
        - id: "ami-0113ae93759fd1462"
        - id: "ami-017f064013f68e6c9"
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_node_pool_arm64" {
  provider  = kubectl
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: arm64
    spec:
      template:
        spec:
          taints:
            - key: role
              value: arm64
              effect: NoSchedule
          requirements:
            - key: kubernetes.io/os
              operator: In
              values: ["linux"]
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["spot"]
            - key: "karpenter.k8s.aws/instance-size"
              operator: In
              values: ["medium"]
            - key: "kubernetes.io/arch"
              operator: In
              values: ["arm64"]
          nodeClassRef:
            group: karpenter.k8s.aws
            kind: EC2NodeClass
            name: arm64
          expireAfter: 720h
      disruption:
        consolidationPolicy: WhenEmpty
        consolidateAfter: 30s
        expireAfter: 720h

  YAML

  depends_on = [
    kubectl_manifest.karpenter_node_class_arm64
  ]
}
