resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "default" {
  vpc_id  = aws_vpc.default.id
}

resource "aws_route" "default" {
  route_table_id = aws_vpc.default.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.default.id
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.default.id
  # Default group should have explicitly no ingress or egress
}
