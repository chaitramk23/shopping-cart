# EC2 instance
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.sg.id]

  tags = {
    Name = "simple-tomcat"
  }
}

output "instance_ip" {
  value = aws_instance.app.public_ip
}

output "private_key_pem" {
  value     = tls_private_key.key.private_key_pem
  sensitive = true
}
