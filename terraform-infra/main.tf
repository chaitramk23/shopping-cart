provider "aws" {
  region = "us-east-1"  # Change to your region
}

# Security Group to allow SSH and HTTP (or Tomcat)
resource "aws_security_group" "sg" {
  name        = "tomcat-sg"
  description = "Allow SSH and HTTP/Tomcat ports"

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

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# EC2 instance
resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  key_name               = "my-jenkins"  # <-- Replace with your key name in AWS
  vpc_security_group_ids = [aws_security_group.sg.id]

  tags = {
    Name = "simple-ec2"
  }
}

# Output the public IP to SSH
output "instance_ip" {
  value = aws_instance.app.public_ip
}
