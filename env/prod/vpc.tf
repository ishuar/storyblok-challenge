module "webapp_eks_vpc" {
  source = "../modules/vpc/"

  vpc_name                  = "storyblok-qa-vpc-${local.region}-01" ## depends on the use case and company conventions
  vpc_cidr                  = "10.10.0.0/16"
  vpc_secondary_cidr_blocks = ["10.11.0.0/16", "10.12.0.0/16"]
  tags                      = local.tags
  one_nat_gateway_per_az    = true ## ::Highlight:: Resiliency and Availability
}
