# Registers (and renews) a domain with Route53 Domains. Registration also creates
# a public hosted zone for it and points the domain's name servers at that zone.
resource "aws_route53domains_domain" "this" {
  domain_name       = var.domain_name
  duration_in_years = var.duration_in_years
  auto_renew        = var.auto_renew

  admin_contact {
    contact_type   = var.contact.contact_type
    first_name     = var.contact.first_name
    last_name      = var.contact.last_name
    email          = var.contact.email
    phone_number   = var.contact.phone_number
    address_line_1 = var.contact.address_line_1
    address_line_2 = var.contact.address_line_2
    city           = var.contact.city
    state          = var.contact.state
    zip_code       = var.contact.zip_code
    country_code   = var.contact.country_code
  }

  registrant_contact {
    contact_type   = var.contact.contact_type
    first_name     = var.contact.first_name
    last_name      = var.contact.last_name
    email          = var.contact.email
    phone_number   = var.contact.phone_number
    address_line_1 = var.contact.address_line_1
    address_line_2 = var.contact.address_line_2
    city           = var.contact.city
    state          = var.contact.state
    zip_code       = var.contact.zip_code
    country_code   = var.contact.country_code
  }

  tech_contact {
    contact_type   = var.contact.contact_type
    first_name     = var.contact.first_name
    last_name      = var.contact.last_name
    email          = var.contact.email
    phone_number   = var.contact.phone_number
    address_line_1 = var.contact.address_line_1
    address_line_2 = var.contact.address_line_2
    city           = var.contact.city
    state          = var.contact.state
    zip_code       = var.contact.zip_code
    country_code   = var.contact.country_code
  }

  # hide contact details from public WHOIS
  admin_privacy      = true
  registrant_privacy = true
  tech_privacy       = true
  billing_privacy    = true

  tags = var.tags

  # destroying this deletes the registration: irreversible, no refund
  lifecycle {
    prevent_destroy = true
  }
}
