# EKS with Karpenter and Spot Instances

This repository deploys an EKS cluster with Karpenter using Terraform. Karpenter is configured to utilize Spot instances for cost efficiency, supporting both x86 (AMD64) and ARM64 (Graviton) architectures.

## Prerequisites

1. Terraform installed on your machine.
2. AWS CLI configured with appropriate permissions.

## Usage

### Steps to Deploy

1. **Create S3 Bucket and DynamoDB Table**:
   Before deploying the EKS cluster, you need to create the resources required for state management. These resources enable centralized state storage and locking, which are critical for collaborative Terraform usage.
   
   Navigate to the `bucket_creation` directory and run the following commands:
   
   ```bash
   terraform init
   terraform apply
   ```

   This step should only be performed once, or if the bucket and table do not already exist.

2. **Deploy the EKS Cluster**:
   Navigate to the environment directory, e.g., `envs/dev`, and run the following commands:
   
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

### Outputs

After deployment, note the EKS cluster endpoint and ID for further usage.

### Running a Pod on Specific Architectures

To run a pod on Spot nodes with specific architectures:

- For x86 (AMD64) Spot instances:
  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: x86-spot-pod
  spec:
    nodeSelector:
      kubernetes.io/arch: amd64
      eks.amazonaws.com/capacityType: SPOT
    tolerations:
      - key: "role"
        operator: "Equal"
        value: "x86"
        effect: "NoSchedule"
    containers:
      - name: nginx
        image: nginx:latest

  ```

- For ARM64 (Graviton) Spot instances:
  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: arm64-spot-pod
  spec:
    nodeSelector:
      kubernetes.io/arch: arm64
      eks.amazonaws.com/capacityType: SPOT
    tolerations:
      - key: "role"
        operator: "Equal"
        value: "arm64"
        effect: "NoSchedule"
    containers:
      - name: nginx
        image: nginx:latest

  ```

### Cleaning Up

To destroy the infrastructure:
```bash
terraform destroy
```

#  GPU Slicing on EKS: Enabling Cost Efficiency for GPU-Intensive Workloads

## Prerequisites

1. NVIDIA Driver: Installed on GPU instances (this is often managed by the NVIDIA device plugin).

```yaml 
  resource "helm_release" "nvidia_device_plugin" {
  name       = "nvidia-device-plugin"
  namespace  = "kube-system"
  chart      = "nvidia-device-plugin"
  repository = "https://nvidia.github.io/k8s-device-plugin"
  version    = "0.14.1" # Use the latest compatible version

  values = [
    <<EOF
      # Customizable Helm values for the NVIDIA Device Plugin
      resources:
        limits:
          nvidia.com/gpu: 1
        requests:
          nvidia.com/gpu: 1
      plugin:
        env:
          - name: "NVIDIA_VISIBLE_DEVICES"
            value: "all"
          - name: "NVIDIA_DRIVER_CAPABILITIES"
            value: "utility,compute"
      EOF
  ]
```

2. Create a new EC2NodeClass and Nodepool
```yaml
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
````

```yaml 
  apiVersion: karpenter.sh/v1alpha1
kind: NodePool
metadata:
  name: gpu-nodepool
spec:
  limits:
    resources:
      "nvidia.com/gpu": "10" # Adjust based on your GPU instance type and slicing requirements
  taints:
    - key: "nvidia.com/gpu"
      value: "present"
      effect: "NoSchedule"
  requirements:
    - key: "karpenter.sh/capacity-type"
      operator: "In"
      values: ["SPOT", "ON_DEMAND"] # Include both Spot and On-Demand if desired
    - key: "kubernetes.io/arch"
      operator: "In"
      values: ["amd64"]
    - key: "instance-type"
      operator: "In"
      values: ["g4dn.xlarge", "g4dn.2xlarge"] # Replace with your preferred GPU instance types
  nodeClassRef:
    name: gpu-ec2-nodeclass
  kubeletConfiguration:
    systemReserved:
      cpu: "500m"
      memory: "512Mi"
    kubeReserved:
      cpu: "500m"
      memory: "512Mi"
```

### Running a Pod on Slicing Architectures

To run a pod on Spot nodes with Slicing architectures:

- For x86 (AMD64) Spot instances:
  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: gpu-slicing-pod
  spec:
    nodeSelector:
      kubernetes.io/arch: amd64
      eks.amazonaws.com/capacityType: SPOT
    tolerations:
      - key: "nvidia.com/gpu"
        operator: "Equal"
        value: "present"
        effect: "NoSchedule"
    containers:
      - name: tensorflow
        image: "tensorflow/tensorflow:latest-gpu"
        resources:
          limits:
            nvidia.com/gpu: 1
          requests:
            nvidia.com/gpu: 1

  ```

