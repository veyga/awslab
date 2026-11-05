locals {
  terragrunt_layer  = path_relative_to_include()
  context           = try(read_terragrunt_config(find_in_parent_folders("context.hcl")).locals, {})
  ctx               = try(local.context.ctx, "NA")
  cluster_full_name = try(local.context.cluster_full_name, "NA")
  # authentik_app_group = try(local.context.authentik_app_group, "ops")
  arch = try(local.context.arch, "NA")
  # ingress_class       = try(local.context.ingress_class, "traefik")
  # cluster_issuer      = try(local.context.cluster_issuer, "clusterissuer-prod")
  # ecr                 = "903832772335.dkr.ecr.us-west-2.amazonaws.com"
  ctx_aws_tags        = try(local.context.aws_tags, {})
  providers_inherited = try(read_terragrunt_config(find_in_parent_folders("providers.hcl")).locals.providers, [])
  providers_override = try(read_terragrunt_config("${get_original_terragrunt_dir()}/providers.hcl").locals.providers,
  [])
  providers = length(local.providers_override) > 0 ? local.providers_override : local.providers_inherited
  # authentik_url  = "https://multipass.netx.us"
  # dockerhub_repo = "netxadmin"

  aws = {
    region  = "us-east-1"
    profile = "aws1" # ~/.aws/config profile used by the provider and the state backend
    tags = merge(
      {
        created_by = "terraform",
      },
      local.ctx_aws_tags
    )
    accounts = {
      default = "519915467343"
    }
  }
}


terragrunt_version_constraint = ">= 1.2.0"
terraform_version_constraint  = ">= 1.17.0"

remote_state {
  backend = "s3"
  config = {
    encrypt      = true
    bucket       = "veyga-awslab-tfstate"
    key          = "${local.terragrunt_layer}/terraform.tfstate"
    region       = "us-east-1"
    profile      = local.aws.profile
    use_lockfile = true # S3-native locking (replaces the deprecated dynamodb_table)
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

generate "provider" {
  path      = "providers.tf"
  if_exists = "overwrite_terragrunt" # dont skip, otherwise we cant version enforce
  contents  = <<EOT
terraform {
  required_version = "> 1.17"
  required_providers {
    %{if contains(local.providers, "aws")}
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.72.0"
    }
    %{endif}
  }
}
EOT
}

# if you change default tags, they are not reflected in previously created resources
# some aws resources don't support 'default_tags'
# you may have to manually include tags argument to certain resources
generate "provider_aws" {
  path      = "provider_aws.tf"
  if_exists = "skip"
  disable   = !(contains(local.providers, "aws"))
  contents  = <<EOT
provider "aws" {
  region  = "${local.aws.region}"
  profile = "${local.aws.profile}"
  default_tags {
    tags = ${jsonencode(local.aws.tags)}
  }
}
EOT
}
