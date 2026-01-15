variable "aws_access_key" {
  type      = string
  sensitive = true
}

variable "aws_secret_key" {
  type      = string
  sensitive = true
}

provider "aws" {
  region = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
variable "vpc_cidr_block" { type = string }
variable "subnet_cidr_block" { type = string }
variable "avail_zone" { type = string }
variable "env_prefix" { type = string }
variable "myip_address" { type = string } 
variable "instance_type" { type = string  }
variable "my_public_key_location" { type = string }

resource "aws_vpc" "myapp_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.env_prefix}-VPC"
  }
}

resource "aws_subnet" "myapp_subnet_1" {
  vpc_id     = aws_vpc.myapp_vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name = "${var.env_prefix}-Subnet-1"
  }
}

resource "aws_route_table" "myapp_route_table" {
  vpc_id = aws_vpc.myapp_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp_igw.id
  }
  tags = {
    Name = "${var.env_prefix}-Route-Table"
  } 
}

resource "aws_internet_gateway" "myapp_igw" {
  vpc_id = aws_vpc.myapp_vpc.id
  tags = {
    Name = "${var.env_prefix}-IGW"
  }
}

resource "aws_route_table_association" "myapp_route_table_subnets" {
  subnet_id = aws_subnet.myapp_subnet_1.id
  route_table_id = aws_route_table.myapp_route_table.id
}


resource "aws_security_group" "myapp_sg" {
  name        = "${var.env_prefix}-SG"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.myapp_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.myip_address]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name = "${var.env_prefix}-SG"
  }
}

data "aws_ami" "latest_amazon_linux_image" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

output "aws_ami_id" {
  value = data.aws_ami.latest_amazon_linux_image.id
}

output "ec2_public_ip" {
  value = aws_instance.myapp_instance.public_ip
}

resource "aws_key_pair" "ssh_server_key" {
  key_name = "server-key" # using our own key name 
  public_key = file("${var.my_public_key_location}")
}

resource "aws_instance" "myapp_instance" {
  ami           = data.aws_ami.latest_amazon_linux_image.id  # "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI (HVM), SSD Volume Type
  instance_type = var.instance_type # "t2.micro"
  subnet_id     = aws_subnet.myapp_subnet_1.id
  vpc_security_group_ids = [aws_security_group.myapp_sg.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true 
  key_name = aws_key_pair.ssh_server_key.key_name

  /*
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd
              echo "<h1>Welcome to ${var.env_prefix} environment</h1>" > /var/www/html/index.html
              EOF
  */

  # multiline user_data from files
user_data = join("\n", [
  file("${path.module}/scripts/apache.sh"),
  file("${path.module}/scripts/docker.sh")
])


  user_data_replace_on_change = true

  tags = {
    Name = "${var.env_prefix}-Instance"
  }
}