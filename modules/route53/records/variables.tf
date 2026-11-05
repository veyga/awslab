variable "zone_name" {
  description = "The Route53 zone name"
  type        = string
}

variable "alias_records" {
  description = "Map of alias records to create"
  type = map(object({
    name                   = string
    target_dns_name        = string
    target_zone_id         = string
    record_type            = string
    evaluate_target_health = bool
  }))
}
