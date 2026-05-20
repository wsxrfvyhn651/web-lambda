resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
}

data "aws_ec2_managed_prefix_list" "dynamodb" {
  name = "com.amazonaws.ap-southeast-1.dynamodb"
}

resource "aws_subnet" "subnet_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-1a"
}

resource "aws_subnet" "subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-southeast-1b"
}

resource "aws_security_group" "lambda_sg" {
  name   = "lambda-vpc-sg"
  vpc_id = aws_vpc.main_vpc.id

  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.dynamodb.id]
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "subnet_1_assoc" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "subnet_2_assoc" {
  subnet_id      = aws_subnet.subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_vpc_endpoint" "dynamodb_endpoint" {
  vpc_id       = aws_vpc.main_vpc.id
  service_name = "com.amazonaws.${var.aws_region}.dynamodb"
}

resource "aws_vpc_endpoint_route_table_association" "connect_to_rt" {
  route_table_id  = aws_route_table.private_rt.id
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb_endpoint.id
}

output "vpc_id" {
  value = aws_vpc.main_vpc.id
}

output "subnet_ids" {
  value = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]
}

output "lambda_sg_id" {
  value = aws_security_group.lambda_sg.id
}