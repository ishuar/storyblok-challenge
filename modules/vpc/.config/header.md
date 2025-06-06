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

  <h1 align="center"><strong>AWS Virtual Private Cloud</strong></h1>
  <p align="center">
    🌩️ Terraform Module For Provisioning AWS Virtual Private Cloud 🌩️
    <br/>
    <a href="https://github.com/ishuar/ppro-aws-terraform-challenge/issues"><strong>Report Bug</a></strong> or <a href="https://github.com/ishuar/ppro-aws-terraform-challenge/issues"><strong>Request Feature</a></strong>
    <br/>
    <br/>
  </p>
</div>

## Background Knowledge or External Documentation

- [What is AWS Virtual Private Cloud?](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)
- [VPC and Subnet Considerations for AWS EKS Service](https://docs.aws.amazon.com/eks/latest/best-practices/subnets.html)

## Introduction

This module is using upstream [AWS VPC Terraform module](https://github.com/terraform-aws-modules/terraform-aws-vpc/tree/master) which creates VPC resources on AWS.

### Usage in scope of current repository

```hcl
module "vpc" {
  source = "PATH_TO_THIS_MODULE"

  vpc_name                  = "ppro-vpc"
  vpc_cidr                  = "10.0.0.0/16"
  vpc_secondary_cidr_blocks = ["10.1.0.0/16", "10.2.0.0/16"] ## max supports 5 entries.
}
```

## NAT Gateway Scenarios

This module supports three scenarios for creating NAT gateways. Each will be explained in further detail in the corresponding sections.

- One NAT Gateway per subnet
  - `enable_nat_gateway = true`
  - `single_nat_gateway = false`
  - `one_nat_gateway_per_az = false`
- Single NAT Gateway  (default behavior)
  - `enable_nat_gateway = true`
  - `single_nat_gateway = true`
  - `one_nat_gateway_per_az = false`
- One NAT Gateway per availability zone
  - `enable_nat_gateway = true`
  - `single_nat_gateway = false`
  - `one_nat_gateway_per_az = true`

If both `single_nat_gateway` and `one_nat_gateway_per_az` are set to `true`, then `single_nat_gateway` takes precedence.

For more details refer to [module documentation](https://github.com/terraform-aws-modules/terraform-aws-vpc/blob/master/README.md#nat-gateway-scenarios)

---
