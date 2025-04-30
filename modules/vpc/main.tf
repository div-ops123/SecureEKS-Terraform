resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  tags = merge(var.common_tags, {Name = "eks-vpc"})
}


######################################
# PUBLIC SUBNETS
######################################
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)       # number of public subnets
  vpc_id                  = aws_vpc.main.id                  # vpc to place the subnet in
  cidr_block              = var.public_subnets[count.index]  # range of ips
  availability_zone       = element(var.AZs, count.index)    # picks AZ by index
  map_public_ip_on_launch = true                             # auto signs a public IP to instances launched in this subnet
  tags                    = merge(var.common_tags, {Name = "public-subnet-${count.index + 1}"})
}


######################################
# PRIVATE SUBNETS
######################################
resource "aws_subnet" "private" {
  count                   = length(var.private_subnets)       # number of public subnets
  vpc_id                  = aws_vpc.main.id                   # vpc to place the subnet in
  cidr_block              = var.private_subnets[count.index]  # range of ips
  availability_zone       = element(var.AZs, count.index)     # picks AZ by index
  tags                    = merge(var.common_tags, {Name = "private-subnet-${count.index + 1}"})
}


######################################
# INTERNET GATEWAY for public access
######################################
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}


######################################
# PUBLIC ROUTE TABLE + Association
######################################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.common_tags, {Name = "public-route-table"})
}

# Adds a route(record) to the route table
# Sends all non-vpc traffic (0.0.0.0/0) to the internet gateway
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


######################################
# NAT Gateway (for private subnets)
######################################
resource "aws_eip" "nat" {
  domain = "vpc"                          # Ensures the EIP is allocated within the VPC
  tags = merge(var.common_tags, { Name = "nat-eip" })
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id  # Place NAT in first public subnet
  tags          = merge(var.common_tags, { Name = "nat-gateway" })

  depends_on = [aws_internet_gateway.main]
}


######################################
# PRIVATE ROUTE TABLE + Association
######################################
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.common_tags, { Name = "private-route-table" })
}

resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}