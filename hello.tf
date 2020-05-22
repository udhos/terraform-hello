# terraform {
#	backend "s3" {
# 		bucket = var.BUCKET_STATE
# 		key = "terraform-state/teste.tfstate"
# 		region = "us-east-1"
# 		encrypt = true
# 	}
#}

# backend does not support variables: var.BUCKET_STATE
# https://github.com/hashicorp/terraform/issues/13022

terraform {
	backend "s3" {
		# bucket is taken from command line: terraform init -backend-config
		key     = "terraform-state/teste.tfstate"
		region  = "us-east-1"
		encrypt = true
	}
}

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

variable "AWS_REGION" {
	type = string
	default = "us-east-2"
}

variable "image" {
	type = map
	default = {
		"us-east-2" = "ami-0f7919c33c90f5b58"
	}
}

provider "aws" {
	region = var.AWS_REGION
}

resource "aws_instance" "ncc1701" {
	ami           = lookup(var.image, var.AWS_REGION)
	instance_type = "t3.small"
	subnet_id     = aws_subnet.subnet_public_2a.id
	iam_instance_profile = aws_iam_instance_profile.instance_profile_ncc1701.name
	tags = {
		Name = "ncc1701"
	}
	#user_data = file("user_data.sh")
	#user_data = data.template_file.user_data_template
	user_data = templatefile("user_data.sh.tf_template", { tf_banner = "banner_defined_from_terraform_template" })
	security_groups = [ aws_security_group.ncc1701.id ]
	provisioner "local-exec" {
		command = "echo writing instance public ip to file: instance_ip_public.txt; echo ${aws_instance.ncc1701.public_ip} > instance_ip_public.txt"
	}
}

# template_file replaced by templatefile function
#data "template_file" "user_data_template" {
#	template = file("user_data.sh.tf_template")
#	vars = {
#		tf_banner = "banner_defined_from_terraform_template"
#	}
#}

resource "aws_security_group" "ncc1701" {
	name        = "ncc1701"
	description = "Allow 8080 inbound traffic"
	vpc_id      = aws_vpc.vpc_test.id

	ingress {
		from_port   = 8080
		to_port     = 8080
		protocol    = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	egress {
		from_port   = 0
		to_port     = 0
		protocol    = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}

	tags = {
		Name = "ncc1701"
	}
}

resource "aws_iam_instance_profile" "instance_profile_ncc1701" {
	name = "instance_profile_ncc1701"
	role = aws_iam_role.ncc1701role.name
}

resource "aws_iam_role_policy_attachment" "role_attach" {
	role       = aws_iam_role.ncc1701role.name
	policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
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

output "instance_ip_public" {
	value = aws_instance.ncc1701.public_ip
}
