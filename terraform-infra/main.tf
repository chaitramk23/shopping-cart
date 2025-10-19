provider "aws" {
  region = "us-east-1"
}

# Create key pair
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "deployer" {
  key_name   = "jenkins-deploy-key"
  public_key = tls_private_key.key.public_key_openssh
}

# Security group
resource "aws_security_group" "sg" {
  name        = "tomcat-sg"
  description = "Allow SSH and Tomcat"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
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
}

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

