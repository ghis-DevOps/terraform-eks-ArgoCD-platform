# Terraform EKS Argo CD Platform

This repository provisions the foundational AWS infrastructure for a Kubernetes platform using Terraform. It creates a VPC and an Amazon EKS cluster with the required networking and IAM integration, and it is intentionally designed as the base layer for later platform add-ons such as Argo CD, cert-manager, external-dns, ALB ingress controller, EFS CSI, Gateway API, and Karpenter.

## Overview

The project is organized into:

- a root Terraform configuration that wires the modules together
- a reusable VPC module
- a reusable EKS module
- environment-specific variable files under `envs/dev`

This is the first step in a broader platform architecture where the cluster is bootstrapped and then enriched with GitOps and Kubernetes operators.

## What gets deployed

- AWS VPC with public and private subnets
- NAT gateway for private subnet internet access
- DNS and networking tags required by EKS and Kubernetes load balancers
- Amazon EKS cluster with public endpoint access
- managed node group for system workloads
- OIDC provider and cluster outputs needed by future IRSA-based add-ons

## Architecture

```text
        ┌─────────────────────────────────────────────┐
        │                AWS Account                  │
        │                                             │
        │  ┌───────────────────────────────────────┐  │
        │  │           VPC / Networking            │  │
        │  │  Public subnets   Private subnets     │  │
        │  │  + NAT + routing + tags              │  │
        │  └───────────────────────────────────────┘  │
        │                     │                       │
        │                     ▼                       │
        │  ┌───────────────────────────────────────┐  │
        │  │          Amazon EKS Cluster           │  │
        │  │  Control plane + managed node group  │  │
        │  │  system workloads                    │  │
        │  └───────────────────────────────────────┘  │
        │                     │                       │
        │                     ▼                       │
        │  ┌───────────────────────────────────────┐  │
        │  │  Future platform add-ons             │  │
        │  │  ArgoCD | cert-manager | ALB        │  │
        │  │  ExternalDNS | EFS CSI | Karpenter  │  │
        │  └───────────────────────────────────────┘  │
        └─────────────────────────────────────────────┘
```

## Project structure

```text
terraform-eks-ArgoCD-platform/
├── .github/
│   └── workflows/
│       └── terraform-ci.yml
├── .terraform.lock.hcl
├── README.md
├── main.tf
├── providers.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── docs/
├── envs/
│   └── dev/
│       ├── README.md
│       └── terraform.tfvars
├── modules/
│   ├── eks/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── vpc/
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
```

## Prerequisites

Before running this project, make sure you have:

- Terraform 1.6.6 or later
- AWS CLI installed and configured
- valid AWS credentials for the target account/region
- `kubectl` installed to interact with the cluster

You should also have permissions to create:

- VPC resources
- EKS cluster resources
- IAM roles and policies
- EC2-related networking objects

## Configuration

The default configuration is defined in `variables.tf`, and environment-specific values are stored in `envs/dev/terraform.tfvars`.

Current defaults include:

- region: `us-east-1`
- cluster name: `platform-dev`
- Kubernetes version: `1.31`
- VPC CIDR: `10.0.0.0/16`
- AZ count: `3`

## Usage

Initialize Terraform:

```bash
terraform init
```

Create the VPC and EKS cluster:

```bash
terraform apply -var-file=envs/dev/terraform.tfvars -target=module.vpc -target=module.eks
```

Then apply the remaining configuration:

```bash
terraform apply -var-file=envs/dev/terraform.tfvars
```

The development `terraform.tfvars` file is excluded from version control. Create
it locally with the values for your environment (for example, `region` and
`cluster_name`) before using the commands above. Do not put credentials or
secrets in this file. The project's defaults are used if you choose not to
provide an environment-specific file.

Configure `kubectl` for the new cluster:

```bash
aws eks update-kubeconfig --region us-east-1 --name platform-dev
```

Alternately, the configuration command is exposed as an output via Terraform:

```bash
$(terraform output -raw configure_kubectl)
```

## GitHub Actions

The workflow in `.github/workflows/terraform-ci.yml` runs for pushes, pull
requests, and manual dispatch. It checks Terraform formatting, initializes
providers without configuring a backend, and validates the root configuration.
Provider versions are recorded in `.terraform.lock.hcl`, and CI uses that lock
file without modifying it.

This workflow is validation-only: it does not authenticate to AWS, create a
Terraform plan, or apply infrastructure changes.

Run the same checks locally from the repository root:

```bash
terraform fmt -check -recursive
terraform init -backend=false -input=false -lockfile=readonly
terraform validate
```

## Outputs

After deployment, Terraform exposes a few useful values:

- cluster name
- cluster endpoint
- OIDC provider ARN
- VPC ID
- kubeconfig update command

These are defined in `outputs.tf` and are useful for connecting downstream modules or platform add-ons.

## Integration points for future modules

The project is set up so that additional cluster services can plug into the EKS foundation using:

- `module.eks.oidc_provider_arn`
- `module.eks.cluster_name`

The commented module sequence in `main.tf` shows the intended order for later components:

```text
alb-controller -> external-dns -> cert-manager -> efs-csi -> gateway-api -> argocd -> karpenter
```

These add-ons are not yet implemented in this repo; they are planned as follow-on modules built on top of the cluster foundation.

## Notes

This repository focuses on the infrastructure foundation only. It does not yet include application workload deployment, GitOps bootstrap, or production hardening beyond a basic EKS setup.

## License

This project is provided as a learning and platform-building example. Use and adapt as needed for your own infrastructure environment.
