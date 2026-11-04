variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name (also used for subnet and Karpenter discovery tags)"
  type        = string
  default     = "platform-dev"
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.31"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 3
}

variable "system_node_instance_types" {
  description = "Instance types for the small system node group (CoreDNS, Karpenter, controllers)"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "system_node_desired_size" {
  type    = number
  default = 2
}

variable "tags" {
  type = map(string)
  default = {
    Project   = "eks-platform"
    ManagedBy = "terraform"
  }
}
