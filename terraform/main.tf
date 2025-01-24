# Configure the S3 backend for Terraform state
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"    # Replace with your S3 bucket name
    key            = "terraform.tfstate"              # Path to state file in the bucket
    region         = "us-east-1"                       # Your AWS region
    encrypt        = true                              # Enable encryption for the state file
    dynamodb_table = "your-dynamodb-lock-table"       # Optional: Use a DynamoDB table for state locking
    acl            = "bucket-owner-full-control"      # Set ACL for the state file
  }
}

# AWS provider configuration
provider "aws" {
  region = "us-east-1"  # Set your desired AWS region
}

# Create an S3 bucket to store both the Terraform state and .env file
resource "aws_s3_bucket" "terraform_state" {
  bucket = "your-terraform-state-bucket"  # Set the name of your S3 bucket
  acl    = "private"                      # Set ACL to private
}

# Upload the .env file to the S3 bucket
resource "aws_s3_bucket_object" "env_file" {
  bucket = aws_s3_bucket.terraform_state.bucket
  key    = ".env"                         # Path where .env will be stored in the S3 bucket
  content = <<-EOF
DB_HOST=db
DB_USER=root
DB_NAME=stargifs
FLASK_PORT=5000
EOF
}

# IAM Policy for S3 bucket access to read and write the tfstate and .env files
resource "aws_iam_policy" "s3_bucket_policy" {
  name        = "S3BucketAccessPolicy"
  description = "Policy to allow access to the S3 bucket for Terraform state and .env file"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = [
          "arn:aws:s3:::your-terraform-state-bucket/terraform.tfstate",  # Terraform state file
          "arn:aws:s3:::your-terraform-state-bucket/.env"                # .env file
        ]
      }
    ]
  })
}

# Attach the IAM policy to an existing EC2 instance profile
resource "aws_iam_role_policy_attachment" "attach_s3_bucket_policy" {
  policy_arn = aws_iam_policy.s3_bucket_policy.arn
  role       = "s3Access"  # Replace with the name of your EC2 IAM role
}

# Generate a new SSH key pair for EC2 instance
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create an AWS EC2 key pair using the generated public key
resource "aws_key_pair" "key_pair" {
  key_name   = "instance-test-key"
  public_key = tls_private_key.example.public_key_openssh
}

# Create a security group for the EC2 instance
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

# Create the EC2 instance and associate it with the IAM role
resource "aws_instance" "docker_instance" {
  ami             = "ami-01816d07b1128cd2d"  # Replace with your desired AMI ID
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.key_pair.key_name
  security_groups = [aws_security_group.sg.name]
  iam_instance_profile = "s3Access"  # Using the pre-existing IAM instance profile

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y git docker
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user
              newgrp docker
              yum install -y libxcrypt-compat
              curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              git clone https://github.com/Ariel-ksenzovsky/star-image-app.git /home/ec2-user/star-image-app
              aws s3 cp s3://your-terraform-state-bucket/.env /home/ec2-user/star-image-app
              cd /home/ec2-user/star-image-app
              docker-compose up -d
              EOF

  tags = {
    Name = "FlaskAppInstance"
  }
}

# Output the public IP of the created EC2 instance
output "public_ip" {
  value = aws_instance.docker_instance.public_ip
}
