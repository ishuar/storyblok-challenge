module "webapp_eks" {
  source = "../modules/eks"

  cluster_name                   = "storyblok-webapp-${local.environment}-${local.region}-01" ## depends on the use case and company conventions
  cluster_version                = "1.31"
  cluster_endpoint_public_access = false ## ::Highlight:: Security

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id                   = module.webapp_eks_vpc.vpc_id
  subnet_ids               = module.webapp_eks_vpc.private_subnets ## ::Highlight:: Security, Resiliency and Availability
  control_plane_subnet_ids = module.webapp_eks_vpc.intra_subnets   ## ::Highlight:: Security, Resiliency and Availability

  cluster_addons = {
    coredns = {
      # Releases: https://docs.aws.amazon.com/eks/latest/userguide/managing-coredns.html
      addon_version = "v1.11.4-eksbuild.2"
      configuration_values = jsonencode({
        tolerations = [
          {
            "key"    = "node-role.kubernetes.io/control-plane"
            "effect" = "NoExecute"
          },
          {
            "key"      = "CriticalAddonsOnly"
            "operator" = "Exists"
          },
          {
            "key"      = "component"
            "operator" = "Equal"
            "value"    = "system"
            "effect"   = "NoSchedule"
          },
          {
            "key"      = "component"
            "operator" = "Equal"
            "value"    = "system"
            "effect"   = "NoExecute"
        }]
      })
    }
    kube-proxy = {
      # Releases: https://docs.aws.amazon.com/eks/latest/userguide/managing-kube-proxy.html
      addon_version = "v1.31.3-eksbuild.2"
    }
    vpc-cni = {
      # Releases: https://github.com/aws/amazon-vpc-cni-k8s/releases
      addon_version = "v1.19.2-eksbuild.5"
      configuration_values = jsonencode({
        # has to be string, otherwise the following error is returned:
        # $.enableNetworkPolicy: boolean found, string expected
        enableNetworkPolicy = "true"
        env = {
          ANNOTATE_POD_IP = "true"
        }
      })
    }
  }

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types           = ["m5.xlarge"] ## if reserved instances then better to use them
    iam_role_use_name_prefix = "false"
    iam_role_additional_policies = {
      # enable SSM Session Manager access to EKS managed nodes
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }
  eks_managed_node_groups = {
    system-addon-node-group = {
      ## ::Highlight::, Resiliency & Availability
      min_size      = 3
      max_size      = 10
      desired_size  = 2
      capacity_type = "ON_DEMAND"
      labels = {
        "node.scayle-payments.com/component"          = "system"
        "node.scayle-payments.com/component-severity" = "business-critical"
        "node.scayle-payments.com/used-case"          = "addons"
      }
      ## ::Highlight::, Resiliency & Availability
      taints = [
        {
          key    = "component"
          value  = "system"
          effect = "NO_SCHEDULE"
        },
        {
          key    = "component"
          value  = "system"
          effect = "NO_EXECUTE"
        }
      ]
    }
    workloads-node-group = {
      ## ::Highlight::, Resiliency & Availability
      min_size      = 3
      max_size      = 10
      desired_size  = 2
      capacity_type = "ON_DEMAND"
      labels = {
        "node.scayle-payments.com/component"          = "workload"
        "node.scayle-payments.com/component-severity" = "business-critical"
        "node.scayle-payments.com/used-case"          = "addons"
      }
      ## ::Highlight::, Resiliency & Availability
      taints = [
        {
          key    = "component"
          value  = "workload"
          effect = "NO_SCHEDULE"
        },
        {
          key    = "component"
          value  = "workload"
          effect = "NO_EXECUTE"
        }
      ]
    }
  }

  # other settings
  # allow to manage access to KMS key via IAM role policies
  # IAM roles which will be allowed to have full access to KMS key
  kms_key_owners = [
    for role in [
      "sso_role_name_one",
      "sso_role_name_two",
    ] :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${local.region}/${role}"
  ]

  tags = local.tags
}
