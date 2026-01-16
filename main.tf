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

resource "aws_vpc" "myapp_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.env_prefix}-VPC"
  }
}

module "myapp_subnet" {
  source = "./modules/subnet"
  vpc_id = aws_vpc.myapp_vpc.id
  subnet_cidr_block = var.subnet_cidr_block
  avail_zone = var.avail_zone
  env_prefix = var.env_prefix
}

module "myapp-server" {
  source = "./modules/webserver"
  vpc_id = aws_vpc.myapp_vpc.id
  subnet_id = module.myapp_subnet.subnet.id
  avail_zone = var.avail_zone
  env_prefix = var.env_prefix
  myip_address = var.myip_address
  instance_type = var.instance_type
  my_public_key_location = var.my_public_key_location
}