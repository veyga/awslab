data "aws_route53_zone" "main" {
  name = var.zone_name
}

resource "aws_route53_record" "alias_records" {
  for_each = var.alias_records

  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.record_type

  alias {
    name                   = each.value.target_dns_name
    zone_id                = each.value.target_zone_id
    evaluate_target_health = each.value.evaluate_target_health
  }
}

