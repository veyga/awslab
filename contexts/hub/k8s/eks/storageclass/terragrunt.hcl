include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/k8s/eks/storageclass"
}

dependencies {
  paths = [
    "${get_terragrunt_dir()}/../cluster"
  ]
}

dependency "efs" {
  config_path = "${get_terragrunt_dir()}/../../../efs"
  mock_outputs = {
    vpc_id          = "asdf"
    private_subnets = []
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  eks_auto = false
  efs = {
    id = dependency.efs.outputs.efs_id
  }
  ebs  = true
  tags = {}
  # running into issues provisioning with tags
  # tags = merge(
  #   include.root.locals.aws.tags,
  #   {
  #     "created_by" = "storageclass"
  #   },
  # )
}
