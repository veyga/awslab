variable "domain_name" {
  description = "domain to register, e.g. veyga.click"
  type        = string
}

variable "duration_in_years" {
  description = "registration length"
  type        = number
  default     = 1
}

variable "auto_renew" {
  description = "renew automatically before expiry"
  type        = bool
  default     = true
}

variable "contact" {
  description = <<EOT
  registrant/admin/tech contact (the same person for all three).
  phone_number format: +<country code>.<number>, e.g. +1.5555550100
  EOT
  type = object({
    contact_type   = optional(string, "PERSON")
    first_name     = string
    last_name      = string
    email          = string
    phone_number   = string
    address_line_1 = string
    address_line_2 = optional(string)
    city           = string
    state          = optional(string)
    zip_code       = string
    country_code   = string
  })
  sensitive = true
}

variable "tags" {
  description = "aws tags"
  type        = map(string)
}
