output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.private_subnets
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "intra_subnets" {
  value = module.vpc.intra_subnets
}

output "cidr" {
  value = var.vpc_cidr
}

output "azs" {
  value = local.azs
}

output "default_security_group" {
  value = module.vpc.default_security_group_id
}
