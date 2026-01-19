locals {
  # Determine which subnets are public (have IGW route or map_public_ip)
  public_subnets = {
    for name, subnet in var.subnets : name => subnet
    if subnet.map_public_ip_on_launch || (
      length([for r in subnet.routes : r if r.gateway_id != null]) > 0
    )
  }
  
  private_subnets = {
    for name, subnet in var.subnets : name => subnet
    if !contains(keys(local.public_subnets), name)
  }
}

# Subnets
resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id                  = var.vpc_id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = each.value.map_public_ip_on_launch

  tags = merge(
    var.tags,
    var.subnet_tags,
    each.value.tags,
    { Name = "${var.name_prefix}-${each.key}" }
  )
}

# Route Tables
resource "aws_route_table" "this" {
  for_each = { for name, subnet in var.subnets : name => subnet if subnet.create_route_table }

  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    var.route_table_tags,
    { Name = "${var.name_prefix}-${each.key}-rt" }
  )
}

# Route Table Associations
resource "aws_route_table_association" "this" {
  for_each = var.subnets

  subnet_id = aws_subnet.this[each.key].id
  route_table_id = each.value.create_route_table ? aws_route_table.this[each.key].id : each.value.route_table_id
}

# Custom Routes from subnet configuration
resource "aws_route" "custom" {
  for_each = merge([
    for subnet_name, subnet in var.subnets : {
      for idx, route in subnet.routes : "${subnet_name}-${idx}" => {
        route_table_id             = subnet.create_route_table ? aws_route_table.this[subnet_name].id : subnet.route_table_id
        destination_cidr_block     = route.destination_cidr_block
        destination_prefix_list_id = route.destination_prefix_list_id
        gateway_id                 = route.gateway_id
        nat_gateway_id             = route.nat_gateway_id
        transit_gateway_id         = route.transit_gateway_id
        vpc_peering_connection_id  = route.vpc_peering_connection_id
        vpc_endpoint_id            = route.vpc_endpoint_id
        network_interface_id       = route.network_interface_id
      }
    } if subnet.create_route_table
  ]...)

  route_table_id             = each.value.route_table_id
  destination_cidr_block     = each.value.destination_cidr_block
  destination_prefix_list_id = each.value.destination_prefix_list_id
  gateway_id                 = each.value.gateway_id
  nat_gateway_id             = each.value.nat_gateway_id
  transit_gateway_id         = each.value.transit_gateway_id
  vpc_peering_connection_id  = each.value.vpc_peering_connection_id
  vpc_endpoint_id            = each.value.vpc_endpoint_id
  network_interface_id       = each.value.network_interface_id
}

# Public Routes (IGW)
resource "aws_route" "public_igw" {
  for_each = var.internet_gateway_id != null ? {
    for name, subnet in local.public_subnets : name => subnet
    if subnet.create_route_table
  } : {}

  route_table_id         = aws_route_table.this[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.internet_gateway_id
}

# Private Routes (NAT Gateway - per AZ)
resource "aws_route" "private_nat_per_az" {
  for_each = var.single_nat_gateway_id == null && length(var.nat_gateway_ids) > 0 ? {
    for name, subnet in local.private_subnets : name => subnet
    if subnet.create_route_table && contains(keys(var.nat_gateway_ids), subnet.availability_zone)
  } : {}

  route_table_id         = aws_route_table.this[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.nat_gateway_ids[each.value.availability_zone]
}

# Private Routes (Single NAT Gateway)
resource "aws_route" "private_nat_single" {
  for_each = var.single_nat_gateway_id != null ? {
    for name, subnet in local.private_subnets : name => subnet
    if subnet.create_route_table
  } : {}

  route_table_id         = aws_route_table.this[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.single_nat_gateway_id
}

# Additional Public Routes
resource "aws_route" "public_additional" {
  for_each = merge([
    for subnet_name, subnet in local.public_subnets : {
      for idx, route in var.public_route_table_routes : "${subnet_name}-pub-${idx}" => {
        route_table_id             = subnet.create_route_table ? aws_route_table.this[subnet_name].id : subnet.route_table_id
        destination_cidr_block     = route.destination_cidr_block
        destination_prefix_list_id = route.destination_prefix_list_id
        gateway_id                 = route.gateway_id
        nat_gateway_id             = route.nat_gateway_id
        transit_gateway_id         = route.transit_gateway_id
        vpc_peering_connection_id  = route.vpc_peering_connection_id
      }
    } if subnet.create_route_table
  ]...)

  route_table_id             = each.value.route_table_id
  destination_cidr_block     = each.value.destination_cidr_block
  destination_prefix_list_id = each.value.destination_prefix_list_id
  gateway_id                 = each.value.gateway_id
  nat_gateway_id             = each.value.nat_gateway_id
  transit_gateway_id         = each.value.transit_gateway_id
  vpc_peering_connection_id  = each.value.vpc_peering_connection_id
}

# Additional Private Routes
resource "aws_route" "private_additional" {
  for_each = merge([
    for subnet_name, subnet in local.private_subnets : {
      for idx, route in var.private_route_table_routes : "${subnet_name}-priv-${idx}" => {
        route_table_id             = subnet.create_route_table ? aws_route_table.this[subnet_name].id : subnet.route_table_id
        destination_cidr_block     = route.destination_cidr_block
        destination_prefix_list_id = route.destination_prefix_list_id
        gateway_id                 = route.gateway_id
        nat_gateway_id             = route.nat_gateway_id
        transit_gateway_id         = route.transit_gateway_id
        vpc_peering_connection_id  = route.vpc_peering_connection_id
      }
    } if subnet.create_route_table
  ]...)

  route_table_id             = each.value.route_table_id
  destination_cidr_block     = each.value.destination_cidr_block
  destination_prefix_list_id = each.value.destination_prefix_list_id
  gateway_id                 = each.value.gateway_id
  nat_gateway_id             = each.value.nat_gateway_id
  transit_gateway_id         = each.value.transit_gateway_id
  vpc_peering_connection_id  = each.value.vpc_peering_connection_id
}

# Network ACLs
resource "aws_network_acl" "this" {
  for_each = { for name, subnet in var.subnets : name => subnet if subnet.create_nacl }

  vpc_id     = var.vpc_id
  subnet_ids = [aws_subnet.this[each.key].id]

  dynamic "ingress" {
    for_each = each.value.nacl_ingress
    content {
      rule_no         = ingress.value.rule_no
      action          = ingress.value.action
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_block      = ingress.value.cidr_block
      ipv6_cidr_block = ingress.value.ipv6_cidr_block
    }
  }

  dynamic "egress" {
    for_each = each.value.nacl_egress
    content {
      rule_no         = egress.value.rule_no
      action          = egress.value.action
      from_port       = egress.value.from_port
      to_port         = egress.value.to_port
      protocol        = egress.value.protocol
      cidr_block      = egress.value.cidr_block
      ipv6_cidr_block = egress.value.ipv6_cidr_block
    }
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-${each.key}-nacl" })
}

# Existing NACL associations
resource "aws_network_acl_association" "existing" {
  for_each = { for name, subnet in var.subnets : name => subnet if !subnet.create_nacl && subnet.nacl_id != null }

  network_acl_id = each.value.nacl_id
  subnet_id      = aws_subnet.this[each.key].id
}

# DB Subnet Group
resource "aws_db_subnet_group" "this" {
  count = var.create_db_subnet_group ? 1 : 0

  name        = var.db_subnet_group_name != null ? var.db_subnet_group_name : "${var.name_prefix}-db-subnet-group"
  description = "DB subnet group for ${var.name_prefix}"
  
  subnet_ids = [
    for name in var.db_subnet_group_subnet_names : aws_subnet.this[name].id
  ]

  tags = merge(var.tags, { Name = var.db_subnet_group_name != null ? var.db_subnet_group_name : "${var.name_prefix}-db-subnet-group" })
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "this" {
  count = var.create_elasticache_subnet_group ? 1 : 0

  name        = var.elasticache_subnet_group_name != null ? var.elasticache_subnet_group_name : "${var.name_prefix}-elasticache-subnet-group"
  description = "ElastiCache subnet group for ${var.name_prefix}"
  
  subnet_ids = [
    for name in var.elasticache_subnet_group_subnet_names : aws_subnet.this[name].id
  ]

  tags = merge(var.tags, { Name = var.elasticache_subnet_group_name != null ? var.elasticache_subnet_group_name : "${var.name_prefix}-elasticache-subnet-group" })
}

# Redshift Subnet Group
resource "aws_redshift_subnet_group" "this" {
  count = var.create_redshift_subnet_group ? 1 : 0

  name        = var.redshift_subnet_group_name != null ? var.redshift_subnet_group_name : "${var.name_prefix}-redshift-subnet-group"
  description = "Redshift subnet group for ${var.name_prefix}"
  
  subnet_ids = [
    for name in var.redshift_subnet_group_subnet_names : aws_subnet.this[name].id
  ]

  tags = merge(var.tags, { Name = var.redshift_subnet_group_name != null ? var.redshift_subnet_group_name : "${var.name_prefix}-redshift-subnet-group" })
}

