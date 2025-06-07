
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.36.0"

  create = var.create

  ## EKS Cluster
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  ## EKS Networking
  cluster_endpoint_private_access       = true ## ::Highlight:: Security
  cluster_endpoint_public_access        = var.cluster_endpoint_public_access
  vpc_id                                = var.vpc_id
  subnet_ids                            = var.subnet_ids               ## ::Highlight:: Security, Resiliency and Availability
  control_plane_subnet_ids              = var.control_plane_subnet_ids ## ::Highlight:: Security, Resiliency and Availability
  cluster_ip_family                     = var.cluster_ip_family
  cluster_service_ipv4_cidr             = var.cluster_service_ipv4_cidr
  cluster_endpoint_public_access_cidrs  = var.cluster_endpoint_public_access_cidrs
  cluster_additional_security_group_ids = var.cluster_additional_security_group_ids

  ## EKS ADDONS
  cluster_addons                = var.cluster_addons
  cluster_addons_timeouts       = var.cluster_addons_timeouts
  bootstrap_self_managed_addons = var.bootstrap_self_managed_addons

  ## EKS Node Groups
  eks_managed_node_group_defaults = var.eks_managed_node_group_defaults
  eks_managed_node_groups         = var.eks_managed_node_groups

  ## EKS Access
  access_entries                           = var.access_entries
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions
  iam_role_name                            = "EksDeploymentServiceRole"
  iam_role_use_name_prefix                 = false

  ## Audit Logging
  cluster_enabled_log_types = var.cluster_enabled_log_types ## ::Highlight:: Security & Audit

  ## Extras
  tags           = var.tags
  kms_key_owners = var.kms_key_owners

}
