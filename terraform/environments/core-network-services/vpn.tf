# Azure FixNGo VPN attachment - tactical solution, to be removed once MP->PTTP->ALZ connection in place

locals {

  egress_fix_n_go_routing_cidrs_non_live_data = {
  "azure-nomis"    = "10.101.0.0/16",
  }

  egress_fix_n_go_routing_cidrs_live_data = {
  "azure-nomis"    = "10.101.0.0/16",
  }
}

resource "aws_customer_gateway" "fix_n_go" {
  bgp_asn    = TBC
  ip_address = TBC
  type       = "ipsec.1"

  tags = merge(local.tags, { Name = "FixNGo" })
}

# VPN Attachments
resource "aws_vpn_connection" "fix_n_go" {
  customer_gateway_id = aws_customer_gateway.fix_n_go.id
  transit_gateway_id  = aws_ec2_transit_gateway.transit-gateway.id
  type                = aws_customer_gateway.fix_n_go.type
  tags                = merge(local.tags, { Name = "FixNGo" })
}

# associate tgw external-inspection-in routing table with Azure FixNGo VPN attachment
resource "aws_ec2_transit_gateway_route_table_association" "external_inspection_in_fix_n_go" {
  transit_gateway_attachment_id  = aws_vpn_connection.fix_n_go.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.external_inspection_in.id
}

# add external egress routes for non-live-data TGW route table to Azure FixNGo attachment
resource "aws_ec2_transit_gateway_route" "tgw_external_egress_routes_for_non_live_data_to_fix_n_go" {
  for_each = local.egress_fix_n_go_routing_cidrs_non_live_data

  destination_cidr_block         = each.value
  transit_gateway_attachment_id  = aws_vpn_connection.fix_n_go.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.route-tables["non_live_data"].id
}
# add external egress routes for live-data TGW route table to Azure FixNGo attachment
resource "aws_ec2_transit_gateway_route" "tgw_external_egress_routes_for_live_data_to_fix_n_go" {
  for_each = local.egress_fix_n_go_routing_cidrs_live_data

  destination_cidr_block         = each.value
  transit_gateway_attachment_id  = aws_vpn_connection.fix_n_go.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.route-tables["live_data"].id
}
