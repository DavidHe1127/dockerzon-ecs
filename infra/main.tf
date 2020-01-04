provider "aws" {
  profile = "qq"
  region  = "ap-southeast-2"
}

# subnets
resource "aws_subnet" "public-subnet" {
  vpc_id                  = aws_vpc.dockerzon-ecs-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-southeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "10.0.1.0/ap-southeast-2a"
  }
}

resource "aws_subnet" "private-subnet" {
  vpc_id            = aws_vpc.dockerzon-ecs-vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-southeast-2b"

  tags = {
    Name = "10.0.2.0/ap-southeast-2b"
  }
}

# vpc
resource "aws_vpc" "dockerzon-ecs-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    env = "dev"
    app = "dockerzon-ecs"
  }

}

# IGW
resource "aws_internet_gateway" "dockerzon-ecs-vpc-igw" {
  vpc_id = aws_vpc.dockerzon-ecs-vpc.id

  tags = {
    name = "dockerzon-ecs-vpc-igw"
  }
}

# Route Table
# default route mapping vpc's cidr to local to allow communication
# between subnets is created implicitly and cannot be specified
resource "aws_route_table" "dockerzon-ecs-vpc-public-route" {
  vpc_id = aws_vpc.dockerzon-ecs-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dockerzon-ecs-vpc-igw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.dockerzon-ecs-vpc-igw.id
  }

  tags = {
    name = "dockerzon-ecs-vpc-public-route"
  }
}

# Route Table association
resource "aws_route_table_association" "dockerzon-ecs-vpc-route-table" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.dockerzon-ecs-vpc-public-route.id
}


# --------------------------------------------------
# with vpc module, it creates IGW for you when specifying public subnet
# Hide required components under the hood not good for me being familiar with VPC
# use native aws_vpc until you master it.

# module "vpc" {
#   source = "terraform-aws-modules/vpc/aws"

#   name = "dockerzon-ecs-vpc"
#   cidr = "10.0.0.0/16"

#   enable_ipv6 = true

#   azs             = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
#   # public_subnets  = ["10.0.1.0/24"]
#   # private_subnets = ["10.0.2.0/24"]

#   # enable_nat_gateway = true
#   # enable_vpn_gateway = true

#   tags = {
#     Terraform   = "true"
#     Environment = "dev"
#   }
# }