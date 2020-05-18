variable "myvar" {
	type = string
	default = "hello terraform"
}

variable "mymap" {
	type = map
	default = {
		mykey = "my value"
	}
}

variable "mylist" {
	type = list
	default = [1,2,3]
}

provider "aws" {
	region = "us-east-2"
}

resource "aws_instance" "ncc1701" {
	ami           = "ami-0f7919c33c90f5b58"
	instance_type = "t2.small"
	subnet_id     = aws_subnet.subnet_public_2a.id
	iam_instance_profile = aws_iam_role.ncc1701role.name
	tags = {
		Name = "ncc1701"
	}
}

resource "aws_iam_role_policy_attachment" "role_attach" {
	role       = aws_iam_role.ncc1701role.name
	policy_arn = "arn:aws:iam::aws:policy:AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role" "ncc1701role" {
	name = "ncc1701role"
	assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_vpc" "vpc_test" {
	cidr_block = "10.10.0.0/16"
	tags = {
		Name = "vpc_test"
	}
}

resource "aws_subnet" "subnet_public_2a" {
	vpc_id                  = aws_vpc.vpc_test.id
	cidr_block              = "10.10.0.0/24"
	map_public_ip_on_launch = true
	availability_zone       = "us-east-2a"
	tags = {
		Name = "subnet_public_2a"
	}
}

resource "aws_internet_gateway" "igw_test" {
	vpc_id = aws_vpc.vpc_test.id
	tags = {
		Name = "igw_test gateway teste"
	}
}

resource "aws_route_table" "rt_public" {
	vpc_id = aws_vpc.vpc_test.id
	tags = {
		Name = "rt_public"
	}
}

resource "aws_route" "internet_access" {
	route_table_id         = aws_route_table.rt_public.id
	destination_cidr_block = "0.0.0.0/0"
	gateway_id             = aws_internet_gateway.igw_test.id
}

resource "aws_route_table_association" "rt_association_public" {
	subnet_id      = aws_subnet.subnet_public_2a.id
	route_table_id = aws_route_table.rt_public.id
}
