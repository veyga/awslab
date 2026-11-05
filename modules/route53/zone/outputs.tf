output "zone_id" {
  value = aws_route53_zone.main.zone_id
}

output "name_servers" {
  description = "set these as the domain's NS records at the registrar"
  value       = aws_route53_zone.main.name_servers
}
