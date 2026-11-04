Run from the repo root:

    terraform init
    terraform apply -var-file=envs/dev/terraform.tfvars -target=module.vpc -target=module.eks
    terraform apply -var-file=envs/dev/terraform.tfvars
