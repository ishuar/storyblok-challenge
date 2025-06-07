# Production Environment Infrastructure

This directory contains the Terraform configuration for the Production environment of our web application infrastructure.

## Architecture Overview

### Core Components

1. **VPC Configuration** (`vpc.tf`):
   - CIDR: 10.10.0.0/16
   - Secondary CIDRs: 10.11.0.0/16, 10.12.0.0/16
   - 3 Availability Zones with High Availability for maximum resilience
   - Subnet Tiers:
     - Public (/24 per AZ) for internet-facing load balancers
     - Private (/24 per AZ) for EKS worker nodes
     - Intra (/24 per AZ) for EKS control plane ENIs
     - Database (/24 per AZ) for RDS and other data services
   - Highly Available NAT Gateways (one per AZ) for fault tolerance
   - VPC Flow Logs to S3 with enhanced monitoring for security auditing

2. **EKS Cluster** (`eks.tf`):
   - Version: 1.31 (matches QA for consistency and proven stability)
   - Private endpoint access only for enhanced security
   - Node Groups:
     - System: 3-10 nodes (m5.xlarge) with dedicated taints
     - Workload: 3-10 nodes (m5.xlarge) with dedicated taints
     - Min 3 nodes for HA distribution across AZs
     - ON_DEMAND capacity type for production reliability
   - Add-ons:
     - CoreDNS v1.11.4-eksbuild.2 with custom tolerations
     - kube-proxy v1.31.3-eksbuild.2
     - vpc-cni v1.19.2-eksbuild.5
   - Security Features:
     - SSM Session Manager access for secure node management
     - KMS encryption with controlled key access
     - Business-critical workload tagging

## Production-Specific Configurations

### High Availability Features
- Multi-AZ NAT Gateways for network resilience (one per AZ)
- Cross-Zone Load Balancing enabled for even distribution
- Node groups with min 3 nodes across 3 AZs for resilience
- Control plane ENIs in isolated Intra subnets
- Automated node replacement and scaling using AutoScaling Groups
- Separate system and workload node groups to avoid noisy neighbor issues

### Security Enhancements
- Private-only cluster endpoint
- VPC Flow Logs with enhanced monitoring to S3
- KMS encryption with controlled key access through SSO roles
- Node security through SSM Session Manager
- Strict node taints and tolerations
- Regular security patches through managed node groups

## Pre-Requisites

1. **Required Tools**:
   ```bash
   brew install terraform awscli kubectl terraform-docs tfsec tflint
   ```

2. **AWS Access**:
   ```bash
   # Configure AWS credentials with production account
   aws configure --profile prod

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
   export AWS_PROFILE=prod-profile  # Production AWS profile
   ```

## Deployment Process

### CI: GitHub Workflows

1. **Triggers & Properties**:
   - Runs on PR to main branch
   - Authentication via OIDC workflow with temporary credentials.
   - Validates Terraform configuration
   - Checks formatting and lint code with `tflint`
   - Generate Plan and post it on Pull request.
   - Security scanning with `tfsec`

2. **Terraform Apply**:
   - Automated Github Workflows
   - Requires PR review approvals
   - Apply only on merge commit on `main` branch.
   - Post-deployment validation
     - Monitoring of business KPI metrics and Dashboards.

### Local Development (Not recommended on Prod)

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
   # Always use plan file in production
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

4. **Access Cluster**:
   ```bash
   aws eks update-kubeconfig --name storyblok-webapp-prod-eu-west-1-01 --region eu-west-1 --profile prod-profile
   kubectl config current-context && kubectl get nodes
   ```

### Emergency Procedures

1. **Rollback Process**:
   - Use terraform plan/apply with older state
   - Have backup of terraform.tfstate
   - Document all changes in change management system

2. **Break Glass Access**:
   - Emergency admin access procedure documented
   - Audit logging of emergency access
   - Post-incident review required

### Security Controls

1. **Node Access**:
   - SSM Session Manager for secure shell access
   - No direct SSH access to nodes
   - Node Permissions: IAM roles with minimal permissions
     - IAM Roles for Kubernetes Service Accounts
   - KMS encryption

2. **Workload Isolation**:
   - System workloads on dedicated nodes
   - Business workloads on separate node groups
   - Usage of taints and tolerations

3. **Network Security**:
   - Private EKS control endpoint.
   - Private subnets for workload nodes
   - Intra subnets for control plane (without internet connection)
   - Security Groups enabled for external access.

### Monitoring & Logging

1. **VPC Flow Logs**:
   - Destination: S3 bucket
   - Format: Parquet

2. **EKS Audit Events**:
   1. For `["audit", "api", "authenticator"]` events.
   2. Forwarded to Cloudwatch via EKS insights.

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

### Disaster Recovery

1. **Backup Strategy**:
   - Regular state file backups
   - Cluster snapshots
   - Cross-region replication
   - Recovery time objectives (RTO)

2. **Recovery Procedures**:
   - Step-by-step recovery guides
   - Regular DR testing
   - Emergency contact list
   - Incident response plan

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
