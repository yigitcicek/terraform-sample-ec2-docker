provider "aws" {
    region = "eu-central-1"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable availability_zone {}
variable env_prefix {}
variable my_ip {}
variable instance_type {}
variable key_name {}

resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name: "${var.env_prefix}-vpc"
    }
}

resource "aws_subnet" "myapp-subnet-001" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.availability_zone
    tags = {
        Name: "${var.env_prefix}-subnet-001"
    }
}

resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id

    tags = {
      "Name" = "${var.env_prefix}-igw"
    }
}

resource "aws_default_route_table" "main-rtb" {
    default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }

    tags = {
      Name = "${var.env_prefix}-main-rtb"
    }
}

resource "aws_default_security_group" "default-sg" {
    vpc_id = aws_vpc.myapp-vpc.id
  
    ingress {
      from_port = 22
      protocol = "tcp"
      to_port = 22
      cidr_blocks = [var.my_ip]
    }

    ingress {
      from_port = 8080
      protocol = "tcp"
      to_port = 8080
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port = 0
      protocol = "-1"
      to_port = 0
      cidr_blocks = ["0.0.0.0/0"]
      prefix_list_ids = []
    }

    tags = {
      Name = "${var.env_prefix}-default-sg"
    }
}

data "aws_ami" "latest-ubuntu-arm64" {
    most_recent = true
    owners = ["099720109477"]

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

    filter {
        name   = "architecture"
        values = ["arm64"]
    }
}

output "aws_ami_id" {
    value = data.aws_ami.latest-ubuntu-arm64.id
}

output "ec2_public_ip" {
    value = aws_instance.myapp-server.public_ip
}

resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.latest-ubuntu-arm64.id
    instance_type = var.instance_type

    subnet_id = aws_subnet.myapp-subnet-001.id
    vpc_security_group_ids = [aws_default_security_group.default-sg.id]
    availability_zone = var.availability_zone

    associate_public_ip_address = true
    key_name = var.key_name

    user_data = file("entry-script.sh")

    tags = {
      Name = "${var.env_prefix}-app-server"
    }
}
