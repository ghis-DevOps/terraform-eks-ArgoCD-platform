data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

module "vpc" {
  source = "./modules/vpc"

  name         = var.cluster_name
  cluster_name = var.cluster_name
  cidr         = var.vpc_cidr
  azs          = local.azs
}

module "eks" {
  source = "./modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids

  system_node_instance_types = var.system_node_instance_types
  system_node_desired_size   = var.system_node_desired_size
}

# Next modules (build in this order):
#   alb-controller -> external-dns -> cert-manager -> efs-csi -> gateway-api -> argocd -> karpenter
# Each one takes module.eks.oidc_provider_arn and module.eks.cluster_name as inputs.
