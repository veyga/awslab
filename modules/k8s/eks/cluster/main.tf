data "aws_caller_identity" "current" {}

locals {
  # Only the account root user is a cluster admin
  access_entries = {
    root = {
      principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # "latest" => let the eks module resolve the newest version compatible with eks_version
  addon_version = { for name, version in var.addon_versions : name => version == "latest" ? null : version }
  addon_latest  = { for name, version in var.addon_versions : name => version == "latest" }
}

module "aws_ebs_csi_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"
  name   = "${var.name}-ebs-csi"

  attach_aws_ebs_csi_policy = true
  tags                      = var.tags
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.14.0"

  name               = var.name
  kubernetes_version = var.eks_version

  # Admin access comes only from local.access_entries (root), not from whoever runs terraform
  enable_cluster_creator_admin_permissions = false
  endpoint_public_access                   = true
  enable_irsa                              = false

  addons = {
    coredns = {
      addon_version               = local.addon_version["coredns"]
      most_recent                 = local.addon_latest["coredns"]
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      configuration_values = jsonencode({
        nodeSelector = {
          "karpenter.sh/controller" = "true"
        }
        tolerations = [
          {
            key      = "karpenter.sh/controller"
            operator = "Equal"
            value    = "true"
            effect   = "NoSchedule"
          }
        ]
      })
    }
    kube-proxy = {
      addon_version               = local.addon_version["kube-proxy"]
      most_recent                 = local.addon_latest["kube-proxy"]
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    vpc-cni = {
      addon_version               = local.addon_version["vpc-cni"]
      most_recent                 = local.addon_latest["vpc-cni"]
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      before_compute              = true
    }
    eks-pod-identity-agent = {
      addon_version               = local.addon_version["eks-pod-identity-agent"]
      most_recent                 = local.addon_latest["eks-pod-identity-agent"]
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      before_compute              = true
    }
    aws-ebs-csi-driver = {
      addon_version               = local.addon_version["aws-ebs-csi-driver"]
      most_recent                 = local.addon_latest["aws-ebs-csi-driver"]
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      pod_identity_association = [{
        role_arn        = module.aws_ebs_csi_pod_identity.iam_role_arn
        service_account = "ebs-csi-controller-sa"
      }]
      configuration_values = jsonencode({
        controller = {
          nodeSelector = {
            "karpenter.sh/controller" = "true"
          }
          tolerations = [
            {
              key      = "karpenter.sh/controller"
              operator = "Equal"
              value    = "true"
              effect   = "NoSchedule"
            }
          ]
        }
      })
    }
  }

  vpc_id                   = var.vpc.id
  subnet_ids               = var.vpc.private_subnets
  control_plane_subnet_ids = var.vpc.intra_subnets
  access_entries           = local.access_entries

  # CONF: eks managed node group kube-system
  # Note: if you accidentally 'kubectl delete' a managed node
  # and a new node isn't being provisioned automatically
  # terminate the underlying EC2 instance of the deleted node
  # (this will be the ec2 with a label of the cluster,
  # but doesn't have a matching k8s node)
  # look for an ip that doesn't exist in 'kubectl get nodes'
  # terminating that instance should trigger a new node
  eks_managed_node_groups = {
    "kube-system-${var.name}" = {
      ami_type       = "BOTTLEROCKET_x86_64"
      instance_types = ["m5.large", "m5.xlarge"]

      min_size     = var.n_managed_nodes
      max_size     = var.n_managed_nodes + 1
      desired_size = var.n_managed_nodes

      labels = {
        "karpenter.sh/controller" = "true"
      }

      taints = {
        karpenter_controller = {
          key    = "karpenter.sh/controller"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }

      node_repair_config = {
        enabled = true
      }

      update_config = {
        max_unavailable = 1
      }

      use_custom_launch_template = false

      launch_template_tags = var.tags
      tag_specifications   = ["instance", "volume", "network-interface"]

      tags = var.tags
    }
  }

  # we want karpenter provisioned nodes to share the same SG as the managed nodes
  # this becomes a bit of a networking/security hassle otherwise
  create_node_security_group = false

  tags = var.tags
}

data "aws_vpc" "cluster_vpc" {
  id = var.vpc.id
}

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 21.2.0"

  cluster_name = module.eks.cluster_name

  # Name needs to match role name passed to the EC2NodeClass
  node_iam_role_use_name_prefix   = false
  node_iam_role_name              = "karpenter-${var.name}"
  create_pod_identity_association = true

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = var.tags
}

# writes a kubeconfig for the cluster (uses the caller's AWS creds, i.e. root)
resource "null_resource" "get_kubeconfig" {
  triggers = {
    name           = var.name
    kubeconfig_out = var.kubeconfig_out
    manifest_hash = sha1(jsonencode({
      cluster_id      = module.eks.cluster_id
      cluster_arn     = module.eks.cluster_arn
      cluster_version = module.eks.cluster_version
      endpoint        = module.eks.cluster_endpoint
    }))
  }

  provisioner "local-exec" {
    command = <<-EOF
      set -ex
      aws eks update-kubeconfig --name ${self.triggers.name} --kubeconfig ${self.triggers.kubeconfig_out}
    EOF
  }

  depends_on = [module.eks]
}
