##############################################################
## Global variables
##############################################################

variable "tags" {
  description = "Tags to be applied to all resources for the module"
  type        = map(string)
  default     = {}
}

##############################################################
## VPC variables
##############################################################

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "vpc_secondary_cidr_blocks" {
  description = "Secondary CIDR blocks for the VPC"
  type        = list(string)
}

##############################################################
## NAT Gateway variables
##############################################################

variable "single_nat_gateway" {
  description = "Create a single NAT Gateway in the VPC"
  type        = bool
  default     = true
}

variable "one_nat_gateway_per_az" {
  description = "Create one NAT Gateway per AZ"
  type        = bool
  default     = false
}
