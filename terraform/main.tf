# Specify the provider
provider "aws" {
  region = "us-east-1" # Specify your AWS region
}

# Data source to reference the existing security group
data "aws_security_group" "existing_sg" {
  filter {
    name   = "group-name"
    values = ["launch-wizard-4"] # Replace with your existing security group's name
  }
}

# Create the EC2 instance
resource "aws_instance" "apache_instance" {
  ami           = "ami-01816d07b1128cd2d" # Replace with your desired AMI ID
  instance_type = "t2.micro"              # Instance type
  key_name      = "instance-test"            # Replace with your existing key pair name

  # Use the existing security group
  vpc_security_group_ids = [data.aws_security_group.existing_sg.id]

  # User data script to install and start Apache
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Apache HTTP Server is running!" > /var/www/html/index.html
              EOF

  # Add tags to the instance
  tags = {
    Name = "Apache-Instance"
  }
}

# Output the public IP address of the instance
output "public_ip" {
  value = aws_instance.apache_instance.public_ip
}

# Local file to store the public IP address
resource "local_file" "public_ip_file" {
  content  = aws_instance.apache_instance.public_ip
  filename = "public_ip.txt"
}

