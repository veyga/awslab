output "hosted_zone_id" {
  description = "hosted zone Route53 created for the domain at registration"
  value       = aws_route53domains_domain.this.hosted_zone_id
}

output "expiration_date" {
  value = aws_route53domains_domain.this.expiration_date
}
