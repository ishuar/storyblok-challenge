<!-- PROJECT SHIELDS -->
<!--
*** declarations on the bottom of this document
managed within the footer file
-->
[![License][license-shield]][license-url] [![Contributors][contributors-shield]][contributors-url] [![Issues][issues-shield]][issues-url] [![Forks][forks-shield]][forks-url] [![Stargazers][stars-shield]][stars-url]


<div id="top"></div>
<!-- PROJECT LOGO -->
<br />
<div align="center">

  <h1 align="center"><strong>AWS Elastic Kubernetes Service</strong></h1>
  <p align="center">
    🌩️ Terraform Module For Provisioning AWS Elastic Kubernetes Service 🌩️
    <br/>
    <a href="https://github.com/ishuar/storyblok-challenge/issues"><strong>Report Bug</a></strong> or <a href="https://github.com/ishuar/storyblok-challenge/issues"><strong>Request Feature</a></strong>
    <br/>
    <br/>
  </p>
</div>

## Background Knowledge or External Documentation

- [What is AWS Elastic Kubernetes Service?](https://docs.aws.amazon.com/de_de/eks/latest/userguide/what-is-eks.html)
- [Amazon EKS Best Practices Guide](https://docs.aws.amazon.com/eks/latest/best-practices/introduction.html)

## Introduction

This module is using upstream [AWS EKS Terraform module](https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master) which creates Amazon EKS (Kubernetes) resources on AWS.

### Usage in scope of current repository with EKS Managed Node Group

```hcl
module "eks" {
  source  = "PATH_TO_THIS_MODULE"

  cluster_name    = "my-cluster"
  cluster_version = "1.31"

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  # Optional
  cluster_endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id                   = "vpc-1234556abcdef"
  subnet_ids               = ["subnet-abcde012", "subnet-bcde012a", "subnet-fghi345a"]
  control_plane_subnet_ids = ["subnet-xyzde987", "subnet-slkjf456", "subnet-qeiru789"]

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
  }

  eks_managed_node_groups = {
    example = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["m5.xlarge"]

      min_size     = 2
      max_size     = 10
      desired_size = 2
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
```

For more details refer to [module documentation](https://github.com/terraform-aws-modules/terraform-aws-eks/blob/v20.36.0/README.md)

---
