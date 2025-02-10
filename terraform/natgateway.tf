# 1) Elastic IP für NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  depends_on = [
    aws_internet_gateway.igw
  ]

  tags = {
    Name = "nat-eip"
  }
}

# 2) NAT Gateway in erstem Public Subnet
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "nat-gw"
  }
}

# 3) Route Table für Private Subnets
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id

  # Standardroute durchs NAT Gateway
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "private-route-table"
  }
}

# 4) Route Table Association für alle privaten Subnets
resource "aws_route_table_association" "private_rt_assoc" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rt.id
}
