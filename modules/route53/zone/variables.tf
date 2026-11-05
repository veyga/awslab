variable "zone_name" {
  description = "dns"
  type        = string
}

variable "tags" {
  description = "aws tags"
  type        = map(string)
}
