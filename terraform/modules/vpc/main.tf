# =============================
# VPC Configuration
# =============================
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(
    var.tags,
    { Name = "${var.environment}-vpc" }
  )
}

# =============================
# Internet Gateway for Public Subnets
# =============================
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.tags,
    { Name = "${var.environment}-igw" }
  )
}

# =============================
# Public Subnets and Route Table
# =============================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.tags,
    { Name = "${var.environment}-public-route-table" }
  )
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "public" {
  # Public subnets in all availability zones
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = merge(
    var.tags,
    { Name = "${var.environment}-public-subnet-${count.index}" }
  )
}

resource "aws_route_table_association" "public" {
  # Associate public subnets with the public route table
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# =============================
# Private Subnets and Route Table
# =============================
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.tags,
    { Name = "${var.environment}-private-route-table" }
  )
}

resource "aws_subnet" "private" {
  # Private subnets in all availability zones
  count             = length(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + length(data.aws_availability_zones.available.names))
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = merge(
    var.tags,
    { Name = "${var.environment}-private-subnet-${count.index}" }
  )
}

resource "aws_route_table_association" "private" {
  # Associate private subnets with the private route table
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# =============================
# Database Subnets and Route Table (No Internet Access)
# =============================
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.tags,
    { Name = "${var.environment}-database-route-table" }
  )
}

resource "aws_subnet" "database" {
  # Database subnets in all availability zones
  count             = length(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 2 * length(data.aws_availability_zones.available.names))
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = merge(
    var.tags,
    { Name = "${var.environment}-database-subnet-${count.index}" }
  )
}

resource "aws_route_table_association" "database" {
  # Associate database subnets with the database route table
  count          = length(aws_subnet.database)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}
