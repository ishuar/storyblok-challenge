# QA Environment Infrastructure

This directory contains the Terraform configuration for the QA environment of our web application infrastructure.

## Architecture Overview

### Core Components

1. **VPC Configuration** (`vpc.tf`):
   - CIDR: 10.0.0.0/16
   - Secondary CIDRs: 10.1.0.0/16, 10.2.0.0/16
   - 3 Availability Zones
   - Subnet Tiers:
     - Public (/24 per AZ)
     - Private (/24 per AZ)
     - Intra (/24 per AZ)
     - Database (/24 per AZ)
   - Single NAT Gateway (cost-optimized)
   - VPC Flow Logs to S3

2. **EKS Cluster** (`eks.tf`):
   - Version: 1.31
   - Private endpoint access
   - Node Groups:
     - System: 2-10 nodes (m5.xlarge)
     - Workload: 2-10 nodes (m5.xlarge)
   - Add-ons:
     - CoreDNS v1.11.4-eksbuild.2
     - kube-proxy v1.31.3-eksbuild.2
     - vpc-cni v1.19.2-eksbuild.5

## Pre-Requisites

1. **Required Tools**:
   ```bash
   brew install terraform awscli kubectl terraform-docs tfsec tflint
   ```

2. **AWS Access**:
   ```bash
   # Configure AWS credentials
   aws configure --profile qa

   # Required permissions:
   # - VPC full access
   # - EKS full access
   # - IAM limited access
   # - S3 access for flow logs
   # - KMS permissions for encryption
   ```

3. **Environment Variables**:
   ```bash
   export AWS_REGION=eu-west-1
   export AWS_PROFILE=qa-profile  # if using named profiles
   ```


## Deployment Process

### CI: GitHub Workflows

The following workflows are configured for this environment:

1. **Triggers & Properties**:
   - Runs on PR to main branch
   - Authentication via OIDC workflow with temporary credentials.
   - Validates Terraform configuration
   - Checks formatting and lint code with `tflint`
   - Runs security scans with `tfsec`
   - Generate Plan and post it on Pull request.


2. **Terraform Apply**:
   - Runs on merge to main
   - **Optional** apply on PR with CI
   - Applies changes to QA environment

### Local Development

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Validate Configuration**:
   ```bash
   terraform validate
   terraform fmt
   tflint
   ```


3. **Plan & Apply Changes**:
   ```bash
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

4. **Access Cluster**:
   ```bash
   aws eks update-kubeconfig --name storyblok-webapp-qa-eu-west-1-01 --region eu-west-1 --profile qa-profile
   kubectl config current-context && kubectl get nodes
   ```

### Security Controls

1. **Node Access**:
   - SSM Session Manager for secure shell access
   - No direct SSH access to nodes
   - IAM roles with minimal permissions
     - IAM Roles for Kubernetes Service Accounts.
   - KMS encryption

2. **Network Security**:
   - Private subnets for all nodes
   - Intra subnets for control plane
   - Security Groups enabled for external access.

## Monitoring & Logging

1. **VPC Flow Logs**:
   - Destination: S3 bucket
   - Format: Parquet

2. **EKS Audit Events**:
   1. For `["audit", "api", "authenticator"]` events.
   2. Forwarded to Cloudwatch via EKS insights.

## Troubleshooting

Common issues and solutions:

1. **VPC Deployment**:
   - Check NAT Gateway status
   - Verify route tables
   - Validate CIDR allocations

2. **EKS Issues**:
   - Check node group auto-scaling
   - Validate add-on versions
   - Review control plane logs


## Next Steps

1. **Compliance**:
   - Regular compliance scans
   - Automated policy checks
   - Drift Detections
   - Audit events forwards to S3 as archives and cost savings from cloudwatch.

2. **Cost Optimisations**:
   - Resource tagging validation
   - Cost optimization reviews
   - Cost dashboards integrations

3. **Observability**:
   - Visibility on Node health
   - Visibility on workloads

## Documentation Updates

Keep this documentation updated with:
- Infrastructure changes
- Process improvements
- Lessons learned
- New security measures

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.11 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.79 |
| <a name="requirement_cloudinit"></a> [cloudinit](#requirement\_cloudinit) | ~> 2.3 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.7 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.98.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_webapp_eks"></a> [webapp\_eks](#module\_webapp\_eks) | ../modules/eks | n/a |
| <a name="module_webapp_eks_vpc"></a> [webapp\_eks\_vpc](#module\_webapp\_eks\_vpc) | ../modules/vpc/ | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->