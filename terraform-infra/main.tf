provider "aws" {
  region = "us-east-1"
}

# Use existing key pair
variable "key_name" {
  default = "jenkins-deploy-key"  # your existing key pair name
}

# Use existing security group
variable "sg_id" {
  default = "sg-xxxxxxxx"  # replace with your existing SG ID
}

# Get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Create EC2 instance
resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [var.sg_id]

  tags = {
    Name = "simple-tomcat"
  }
}

# Output the public IP
output "instance_ip" {
  value = aws_instance.app.public_ip
}
