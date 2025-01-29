terraform {
  backend "s3" {
    bucket = "my-bucket101110101"  # Your existing S3 bucket for state and .env
    key    = "terraform/terraform.tfstate"  # Path for the Terraform state file
    region = "us-east-1"  # Your AWS region
    encrypt = true  # Enable encryption for the state file
  }
}

provider "aws" {
  region = "us-east-1"
}

# Generate a new SSH key pair
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create an AWS key pair using the generated public key
resource "aws_key_pair" "key_pair" {
  key_name   = "instance-test-key"
  public_key = tls_private_key.example.public_key_openssh
}

# Create the security group with necessary ports
resource "aws_security_group" "sg" {
  name_prefix = "terraform-sg-"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
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

# Create the EC2 instance and associate the existing IAM role
resource "aws_instance" "docker_instance" {
  ami             = "ami-0df8c184d5f6ae949"  # Replace with your desired AMI ID
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.key_pair.key_name
  security_groups = [aws_security_group.sg.name]

  iam_instance_profile = "s3Access" # Reference the existing IAM instance profile directly

  user_data = <<-EOF
              #!/bin/bash

              # Update the system and install Ansible
              sudo yum update -y
              sudo yum install -y git ansible

              # Clone the repository containing the Ansible playbook
              git clone https://github.com/Ariel-ksenzovsky/star-image-app.git /home/ec2-user/star-image-app

              # Run the Ansible playbook
              ansible-playbook /home/ec2-user/star-image-app/ansible-flask-app.yml
              EOF

  tags = {
    Name = "FlaskAppInstance"
  }
}

# Output the public IP of the created EC2 instance
output "public_ip" {
  value = aws_instance.docker_instance.public_ip
}
