provider "aws" {
  region              = "eu-west-1"
  allowed_account_ids = ["12345667900"] ## This is the account id of the account that we are managing.

  # The provider will assume the role in the account specified by the account_id
  # and use the credentials of that role to manage the resources in that account.
  # This is useful when you have established a cross-account role and allow specific repositories (github OIDC auth with AWS)
  # but not only limited to that. We could also use a role in the same account
  # to assume that role and manage the resources in that account.

  # assume_role {
  #   role_arn     = "arn:aws:iam::${local.account_id}:role/${local.iam_iaac_role_name}" ## github workflow/repo should we allowed to assume this role.
  #   session_name = "${local.environment}-webapp-infra"
  # }

  default_tags {
    tags = {
      environment          = "prod"
      project              = "storyblok-aws-webapp-infra"
      github_repo          = "storyblok-aws-terraform-challenge"
      owner                = "ishuar"
      managed_by_terraform = "true"
    }
  }
}

# terraform {
#   backend "s3" {

#     ## if we need to store terraform state in a centralized Account.
#     ## then need to use IAM role that have trust relationship with the centralized account
#     ## to manage the terraform state.
#     ##! Variables are not available in the backend block. These are placeholders. (Terragrunt can help with backend generators)
#     # assume_role = {
#     #   role_arn     = "arn:aws:iam::${local.account_id}:role/${local.iam_iaac_role_name}" ## github workflow/repo should we allowed to assume this role.
#     #   session_name = "${local.environment}-webapp-infra"
#     # }
#     bucket       = "the_most_unique_bucket_name" ## [project]-[env]-[data-type]-[identifier] -> "webapp-prod-terraform-state-ew1" bucket should be pre-created.
#     key          = "prod/terraform.tfstate"
#     region       = "eu-west-1"
#     use_lockfile = true
#     encrypt      = true
#   }
# }
