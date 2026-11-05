output "nlb_dns_name" {
  description = "DNS name of the traefik NLB"
  value       = try(data.aws_lb.traefik[0].dns_name, null)
}

output "nlb_zone_id" {
  description = "Route53 hosted zone id of the traefik NLB (for alias records)"
  value       = try(data.aws_lb.traefik[0].zone_id, null)
}
