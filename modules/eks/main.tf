module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true
  enable_irsa                              = true # creates the OIDC provider for IRSA

  cluster_addons = {
    coredns                = {}
    kube-proxy             = {}
    vpc-cni                = {}
    eks-pod-identity-agent = {}
  }

  # Small managed node group for system pods. Karpenter later provisions everything else.
  eks_managed_node_groups = {
    system = {
      instance_types = var.system_node_instance_types
      min_size       = 2
      max_size       = 3
      desired_size   = var.system_node_desired_size

      labels = {
        "node-role" = "system"
      }
    }
  }

  # Lets Karpenter discover the node security group
  node_security_group_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }
}
