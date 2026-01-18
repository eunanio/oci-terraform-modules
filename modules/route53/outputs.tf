output "zone_id" {
  description = "The hosted zone ID"
  value       = aws_route53_zone.this.zone_id
}

output "zone_arn" {
  description = "The ARN of the hosted zone"
  value       = aws_route53_zone.this.arn
}

output "name_servers" {
  description = "A list of name servers for the hosted zone"
  value       = aws_route53_zone.this.name_servers
}

output "primary_name_server" {
  description = "The primary name server for the hosted zone"
  value       = aws_route53_zone.this.primary_name_server
}

output "zone_name" {
  description = "The name of the hosted zone"
  value       = aws_route53_zone.this.name
}

output "dnssec_key_signing_key_id" {
  description = "The ID of the DNSSEC key signing key (if enabled)"
  value       = try(aws_route53_key_signing_key.this[0].id, null)
}

output "dnssec_ds_record" {
  description = "The DS record value for DNSSEC (to be added to parent zone)"
  value       = try(aws_route53_key_signing_key.this[0].ds_record, null)
}

output "health_check_ids" {
  description = "Map of health check names to their IDs"
  value       = { for k, v in aws_route53_health_check.this : k => v.id }
}

output "record_fqdns" {
  description = "Map of record identifiers to their FQDNs"
  value       = { for k, v in aws_route53_record.this : k => v.fqdn }
}

output "record_names" {
  description = "Map of record identifiers to their names"
  value       = { for k, v in aws_route53_record.this : k => v.name }
}

