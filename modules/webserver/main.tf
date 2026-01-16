
resource "aws_security_group" "myapp_sg" {
  name        = "${var.env_prefix}-SG"
  description = "Allow inbound traffic"
  vpc_id      = var.vpc_id

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



resource "aws_key_pair" "ssh_server_key" {
  key_name = "server-key" # using our own key name 
  public_key = file("${var.my_public_key_location}")
}

resource "aws_instance" "myapp_instance" {
  ami           = data.aws_ami.latest_amazon_linux_image.id  # "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI (HVM), SSD Volume Type
  instance_type = var.instance_type # "t2.micro"

  subnet_id     = var.subnet_id
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