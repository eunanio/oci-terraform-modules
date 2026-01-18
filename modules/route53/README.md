# Route53 Module

Creates and manages AWS Route53 hosted zones and DNS records with support for all record types, routing policies, health checks, and DNSSEC.

## Features

- **Hosted Zones**: Public and private zones with VPC associations
- **DNS Records**: All record types (A, AAAA, CNAME, MX, TXT, NS, SRV, CAA, etc.)
- **Alias Records**: Point to AWS resources (ALB, CloudFront, S3, API Gateway, etc.)
- **Routing Policies**: Weighted, latency, geolocation, failover, multivalue, and IP-based
- **Health Checks**: HTTP, HTTPS, TCP, and calculated health checks
- **DNSSEC**: Key signing and zone signing with KMS integration
- **Query Logging**: CloudWatch Logs integration

## Usage with Nori

```bash
nori release create my-domain ghcr.io/your-org/route53:v1.0.0 -f values.yaml
```

## Usage with OpenTofu/Terraform

```hcl
module "route53" {
  source = "oci://ghcr.io/your-org/route53?tag=v1.0.0"

  zone_name = "example.com"
  comment   = "Production domain"

  records = [
    {
      name = ""
      type = "A"
      alias = {
        name    = "dualstack.my-alb.us-east-1.elb.amazonaws.com"
        zone_id = "Z35SXDOTRQ7X7K"
      }
    },
    {
      name    = "www"
      type    = "CNAME"
      ttl     = 300
      records = ["example.com"]
    }
  ]

  tags = {
    Environment = "production"
  }
}
```

## Values File Example

```yaml
# values.yaml
zone_name: example.com
comment: Production DNS zone
force_destroy: false

# === Private Zone Configuration ===
# private_zone: true
# vpc_associations:
#   - vpc_id: vpc-abc123
#     vpc_region: us-east-1
#   - vpc_id: vpc-def456
#     vpc_region: us-west-2

# === DNSSEC Configuration ===
# dnssec_signing:
#   enabled: true
#   # Optionally provide your own KMS key, otherwise one will be created
#   # kms_key_arn: arn:aws:kms:us-east-1:123456789012:key/abc-123

# === Query Logging ===
# query_logging:
#   cloudwatch_log_group_arn: arn:aws:logs:us-east-1:123456789012:log-group:/aws/route53/example.com

# === DNS Records ===
records:
  # Root domain - Alias to ALB
  - name: ""
    type: A
    alias:
      name: dualstack.my-alb.us-east-1.elb.amazonaws.com
      zone_id: Z35SXDOTRQ7X7K
      evaluate_target_health: true

  # www subdomain - CNAME to root
  - name: www
    type: CNAME
    ttl: 300
    records:
      - example.com

  # API subdomain - Alias to API Gateway
  - name: api
    type: A
    alias:
      name: d-abc123.execute-api.us-east-1.amazonaws.com
      zone_id: Z1UJRXOUMOOFQ8
      evaluate_target_health: false

  # Static assets - Alias to CloudFront
  - name: static
    type: A
    alias:
      name: d1234.cloudfront.net
      zone_id: Z2FDTNDATAQYW2
      evaluate_target_health: false

  # Mail server records
  - name: ""
    type: MX
    ttl: 300
    records:
      - 10 mail1.example.com
      - 20 mail2.example.com

  - name: mail1
    type: A
    ttl: 300
    records:
      - 10.0.1.10

  - name: mail2
    type: A
    ttl: 300
    records:
      - 10.0.1.11

  # SPF record
  - name: ""
    type: TXT
    ttl: 300
    records:
      - "v=spf1 include:_spf.google.com ~all"

  # DKIM record
  - name: google._domainkey
    type: TXT
    ttl: 300
    records:
      - "v=DKIM1; k=rsa; p=MIIBIjANBgkqhki..."

  # DMARC record
  - name: _dmarc
    type: TXT
    ttl: 300
    records:
      - "v=DMARC1; p=reject; rua=mailto:dmarc@example.com"

  # CAA record (certificate authority authorization)
  - name: ""
    type: CAA
    ttl: 300
    records:
      - 0 issue "letsencrypt.org"
      - 0 issue "amazonaws.com"
      - 0 iodef "mailto:security@example.com"

  # Weighted routing example
  - name: app
    type: A
    ttl: 60
    records:
      - 10.0.1.100
    routing_policy:
      weighted:
        weight: 70
        set_identifier: primary

  - name: app
    type: A
    ttl: 60
    records:
      - 10.0.2.100
    routing_policy:
      weighted:
        weight: 30
        set_identifier: secondary

  # Latency-based routing example
  - name: global
    type: A
    ttl: 60
    records:
      - 10.0.1.100
    routing_policy:
      latency:
        region: us-east-1
        set_identifier: us-east

  - name: global
    type: A
    ttl: 60
    records:
      - 10.1.1.100
    routing_policy:
      latency:
        region: eu-west-1
        set_identifier: eu-west

  # Geolocation routing example
  - name: geo
    type: A
    ttl: 60
    records:
      - 10.0.1.100
    routing_policy:
      geolocation:
        country: US
        set_identifier: united-states

  - name: geo
    type: A
    ttl: 60
    records:
      - 10.1.1.100
    routing_policy:
      geolocation:
        continent: EU
        set_identifier: europe

  - name: geo
    type: A
    ttl: 60
    records:
      - 10.2.1.100
    routing_policy:
      geolocation:
        country: "*"
        set_identifier: default

  # Failover routing example
  - name: failover
    type: A
    ttl: 60
    records:
      - 10.0.1.100
    health_check_id: primary-health-check
    routing_policy:
      failover:
        type: PRIMARY
        set_identifier: primary

  - name: failover
    type: A
    ttl: 60
    records:
      - 10.0.2.100
    routing_policy:
      failover:
        type: SECONDARY
        set_identifier: secondary

# === Health Checks ===
health_checks:
  primary-health-check:
    type: HTTPS
    fqdn: app.example.com
    port: 443
    resource_path: /health
    failure_threshold: 3
    request_interval: 30
    tags:
      Purpose: primary-failover

  api-health-check:
    type: HTTPS
    fqdn: api.example.com
    port: 443
    resource_path: /v1/health
    search_string: "healthy"
    failure_threshold: 2
    request_interval: 10

  tcp-health-check:
    type: TCP
    ip_address: 10.0.1.100
    port: 3306
    failure_threshold: 3

# === Tags ===
tags:
  Environment: production
  ManagedBy: nori
  Team: platform
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| zone_name | Name of the hosted zone | `string` | n/a | yes |
| comment | Comment for the hosted zone | `string` | `""` | no |
| force_destroy | Destroy all records when destroying the zone | `bool` | `false` | no |
| private_zone | Whether this is a private hosted zone | `bool` | `false` | no |
| vpc_associations | VPC associations for private zones | `list(object)` | `[]` | no |
| delegation_set_id | ID of reusable delegation set | `string` | `null` | no |
| dnssec_signing | DNSSEC signing configuration | `object` | `null` | no |
| query_logging | Query logging configuration | `object` | `null` | no |
| records | List of DNS records to create | `list(object)` | `[]` | no |
| health_checks | Map of health checks to create | `map(object)` | `{}` | no |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| zone_id | The hosted zone ID |
| zone_arn | The ARN of the hosted zone |
| name_servers | A list of name servers for the hosted zone |
| primary_name_server | The primary name server for the hosted zone |
| zone_name | The name of the hosted zone |
| dnssec_key_signing_key_id | The ID of the DNSSEC key signing key |
| dnssec_ds_record | The DS record value for DNSSEC (for parent zone) |
| health_check_ids | Map of health check names to their IDs |
| record_fqdns | Map of record identifiers to their FQDNs |
| record_names | Map of record identifiers to their names |

## Common Alias Zone IDs

Use these zone IDs when creating alias records to AWS services:

| Service | Zone ID | Notes |
|---------|---------|-------|
| CloudFront | `Z2FDTNDATAQYW2` | Global |
| S3 Website (us-east-1) | `Z3AQBSTGFYJSTF` | Region-specific |
| ALB/NLB | Check AWS docs | Region-specific |
| API Gateway | Check AWS docs | Region-specific |
| Global Accelerator | `Z2BJ6XQ5FK7U4H` | Global |

