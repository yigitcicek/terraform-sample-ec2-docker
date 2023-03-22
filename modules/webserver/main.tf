resource "aws_default_security_group" "default-sg" {
    vpc_id = var.vpc_id
  
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
        values = [var.image_name]
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

resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.latest-ubuntu-arm64.id
    instance_type = var.instance_type

    subnet_id = var.subnet_id
    vpc_security_group_ids = [aws_default_security_group.default-sg.id]
    availability_zone = var.availability_zone

    associate_public_ip_address = true
    key_name = var.key_name

    user_data = file("entry-script.sh")

    tags = {
      Name = "${var.env_prefix}-app-server"
    }
}