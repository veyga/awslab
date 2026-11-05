variable "ebs" {
  type = bool
}

variable "tags" {
  description = "Tags to apply to provisioned AWS resources"
  type        = map(string)
}
