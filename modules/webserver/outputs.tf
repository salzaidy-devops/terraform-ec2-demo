output "aws_ami_id" {
  value = data.aws_ami.latest_amazon_linux_image.id
}

output "ec2_public_ip" {
  value = aws_instance.myapp_instance.public_ip
}

output "ec2_public_dns" {
  value = aws_instance.myapp_instance.public_dns
}
