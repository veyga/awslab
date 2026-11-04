variable "name" {
  description = "name for the vpc"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR"
  type        = string
}

variable "public_subnet_tags" {
  description = "tags for the public subnets"
  type        = map(string)
}

variable "private_subnet_tags" {
  description = "tags for the private subnets"
  type        = map(string)
}

variable "aws_tags" {
  description = "general aws tags for vpc"
  type        = map(string)
}
