locals {
  terragrunt_layer    = path_relative_to_include()
  context             = try(read_terragrunt_config(find_in_parent_folders("context.hcl")).locals, {})
  ctx                 = try(local.context.ctx, "NA")
  cluster_full_name   = try(local.context.cluster_full_name, "NA")
  # authentik_app_group = try(local.context.authentik_app_group, "ops")
  arch                = try(local.context.arch, "NA")
  # ingress_class       = try(local.context.ingress_class, "traefik")
  # cluster_issuer      = try(local.context.cluster_issuer, "clusterissuer-prod")
  # ecr                 = "903832772335.dkr.ecr.us-west-2.amazonaws.com"
  ctx_aws_tags        = try(local.context.aws_tags, {})
  providers_inherited = try(read_terragrunt_config(find_in_parent_folders("providers.hcl")).locals.providers, [])
  providers_override = try(read_terragrunt_config("${get_original_terragrunt_dir()}/providers.hcl").locals.providers,
  [])
  providers      = length(local.providers_override) > 0 ? local.providers_override : local.providers_inherited
  # authentik_url  = "https://multipass.netx.us"
  # dockerhub_repo = "netxadmin"

  aws = {
    region = "us-east-1"
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


terragrunt_version_constraint = ">= 0.93.12"
terraform_version_constraint  = ">= 1.12.2"
iam_role                      = "arn:aws:iam::${local.aws.accounts.default}:role/Administrator"

remote_state {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = "netx-iiify-tfstate"
    key            = "${local.terragrunt_layer}/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "netx-iiify-terraform-locks"
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
  required_version = "> 1.5"
  required_providers {
    %{if contains(local.providers, "aws")}
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.28.0"
    }
    %{endif}
    %{if contains(local.providers, "helm")}
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.2"
    }
    %{endif}
    %{if contains(local.providers, "kubernetes")}
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }
    %{endif}
    %{if contains(local.providers, "tls")}
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    %{endif}
    %{if contains(local.providers, "rancher")}
    rancher2 = {
      source  = "rancher/rancher2"
      version = "~> 7.2.0"
    }
    %{endif}
    %{if contains(local.providers, "authentik")}
    authentik = {
      source  = "goauthentik/authentik"
      version = "2025.8.1"
    }
    %{endif}
    %{if contains(local.providers, "gitlab")}
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "18.3.0"
    }
    %{endif}
    %{if contains(local.providers, "vault")}
    vault = {
      source  = "hashicorp/vault"
      version = "5.3.0"
    }
    %{endif}
    %{if contains(local.providers, "docker")}
    docker = {
      source  = "docker/docker"
      version = "0.5.6"
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
  region = "${local.aws.region}"
  default_tags {
    tags = ${jsonencode(local.aws.tags)}
  }
}
EOT
}

generate "provider_helm" {
  path      = "provider_helm.tf"
  if_exists = "skip"
  disable   = !(contains(local.providers, "helm"))
  contents  = <<EOT
provider "helm" {
  kubernetes = {
    config_path    = "~/.kube/config"
    config_context = "${local.ctx}"
  }
}
EOT
}

# generate "provider_kubernetes" {
#   path      = "provider_kubernetes.tf"
#   if_exists = "skip"
#   disable   = !(contains(local.providers, "kubernetes"))
#   contents = <<EOT
# provider "kubernetes" {
#   config_path = "${get_parent_terragrunt_dir()}/${local.ctx}.yaml"
#   config_context = "${local.ctx}"
# }
# EOT
# }

generate "provider_kubernetes" {
  path      = "provider_kubernetes.tf"
  if_exists = "skip"
  disable   = !(contains(local.providers, "kubernetes"))
  contents  = <<EOT
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "${local.ctx}"
}
EOT
}

generate "provider_rancher" {
  path      = "provider_rancher.tf"
  if_exists = "skip"
  disable   = !(contains(local.providers, "rancher"))
  contents  = <<EOT
provider "rancher2" {
  api_url = "https://mc.ops.netx.us"
  token_key = "${get_env("RANCHER_TOKEN_KEY")}"
}
EOT
}

generate "provider_authentik" {
  path      = "provider_authentik.tf"
  if_exists = "skip"
  disable   = !(contains(local.providers, "authentik"))
  contents  = <<EOT
provider "authentik" {
  url   = "${local.authentik_url}"
  token = "${get_env("AUTHENTIK_TOKEN")}"
}
EOT
}

generate "provider_gitlab" {
  path      = "provider_gitlab.tf"
  if_exists = "skip"
  disable   = !(contains(local.providers, "gitlab"))
  contents  = <<EOT
provider "gitlab" {
  base_url = "https://gitlab.netx.net"
  token = "${get_env("GITLAB_PAT_INFRASTRUCTURE_RUNNER")}"
}
EOT
}

generate "provider_vault" {
  path      = "provider_vault.tf"
  if_exists = "skip"
  disable   = !(contains(local.providers, "vault"))
  contents  = <<EOT
provider "vault" {
  address = "https://vault.netx.us"
}
EOT
}

# uses your creds obtained via 'docker login'
generate "provider_docker" {
  path      = "provider_docker.tf"
  if_exists = "skip"
  disable   = !(contains(local.providers, "docker"))
  contents  = <<EOT
provider "docker" {
}
EOT
}
