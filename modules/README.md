# Modules Directory

This directory contains reusable infrastructure-as-code modules for AWS resources, following best practices and enterprise standards.

## What is this directory?

The `modules` directory serves as a central repository for reusable Terraform modules that help provision and manage AWS infrastructure components. Each module is designed to be self-contained, well-documented, and follows infrastructure-as-code best practices.

## What does it include?

### 1. [VPC Module](./vpc)
A Terraform module for provisioning AWS Virtual Private Cloud (VPC) resources:
- Based on the official [AWS VPC Terraform module](https://github.com/terraform-aws-modules/terraform-aws-vpc/tree/master)
- Supports multiple NAT Gateway deployment scenarios
- Includes VPC Flow Logs with S3 bucket integration
- Configurable subnet architecture (public, private, database, intra)
- IPv6 support and DNS configuration
- Tagged subnets for EKS compatibility

### 2. [EKS Module](./eks)
A Terraform module for deploying Amazon Elastic Kubernetes Service (EKS) clusters:
- Built on the official [AWS EKS Terraform module](https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master)
- Managed node group support
- Configurable cluster addons (CoreDNS, kube-proxy, VPC CNI)
- OIDC provider integration
- Kubernetes version management
- Security group and IAM role configurations

## CI/CD Integration

The modules are integrated with GitHub Actions workflows for automated testing and validation:

### VPC Module CI ([`vpc-module-lint.yaml`](../.github/workflows/vpc-module-lint.yaml))

```yaml
Triggers:
- Pull requests targeting main branch
- Changes to modules/vpc/**
- Manual workflow dispatch

Features:
- Terraform configuration validation
- terraform-docs validation
- Concurrent execution protection
```

### EKS Module CI ([`eks-module-lint.yaml`](../.github/workflows/eks-module-lint.yaml))

```yaml
Triggers:
- Pull requests targeting main branch
- Changes to modules/eks/**
- Manual workflow dispatch

Features:
- Terraform configuration validation
- terraform-docs validation
- Concurrent execution protection
```

### Development Workflow

### Pre-requisites

| Name           | Version Used           | Help                                                                                                 | Required                    |
|----------------|------------------------|------------------------------------------------------------------------------------------------------|-----------------------------|
| Terraform      | `>= 1.6.0`             | [Install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) | Yes                         |
| AWS Account    | `N/A`                  | [Create AWS account](https://aws.amazon.com/resources/create-account/)                               | Yes                         |
| terraform-docs | `v0.20.0 darwin/arm64` | [Install terraform-docs CLI](https://terraform-docs.io/user-guide/installation/)                     | Yes |


1. **Module Development**
   - Create a new branch from `main`
   - Make changes to module code
   - Update module documentation using `terraform-docs`
   - Create pull request

2. **Automated Checks**
   - GitHub Actions automatically runs:
     - Terraform format check
     - Terraform validation
     - Documentation validation
     - AWS validations using `tflint`

3. **Review & Merge**
   - Code review required
   - All checks must pass
   - Changes merged to main branch

> [!Tip]
> Helpful Commands using `Makefile`

-  `make fmt`  ->  Formatting terraform code
-  `make docs` -> Generating docs using `terraform-docs` with appropriate config file.

## Best Practices

- Always update module documentation when making changes
- Follow semantic versioning for module releases
- Write clear and concise variable/output descriptions
- Include examples in module README files
- Tag resources appropriately
- Use consistent code formatting
- Implement proper security controls
- Test modules thoroughly before releases

For more detailed information about each module, please refer to their respective README files:
- [VPC Module Documentation](./vpc/README.md)
- [EKS Module Documentation](./eks/README.md)


