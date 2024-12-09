# Configure AWS Provider
provider "aws" {
  region = "us-east-1" # Desired region where to build your infrastructure
}

# Create VPC resources (assuming you want a new VPC)
resource "aws_vpc" "gitlab_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "gitlab-runner-vpc"
  }
}

resource "aws_subnet" "gitlab_subnet" {
  vpc_id                  = aws_vpc.gitlab_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a" # Change according to your region

  tags = {
    Name = "gitlab-runner-subnet"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "gitlab_igw" {
  vpc_id = aws_vpc.gitlab_vpc.id

  tags = {
    Name = "gitlab-runner-igw"
  }
}

# Create Route Table
resource "aws_route_table" "gitlab_route_table" {
  vpc_id = aws_vpc.gitlab_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gitlab_igw.id
  }

  tags = {
    Name = "gitlab-runner-rt"
  }
}

resource "aws_route_table_association" "gitlab_rta" {
  subnet_id      = aws_subnet.gitlab_subnet.id
  route_table_id = aws_route_table.gitlab_route_table.id
}

# Create Security Group
resource "aws_security_group" "gitlab_runner_sg" {
  name        = "gitlab-runner-sg"
  description = "Security group for GitLab runner"
  vpc_id      = aws_vpc.gitlab_vpc.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # cidr_blocks = ["YOUR_IP_ADDRESS/32"]  if it was to Restrict to your IP for ssh
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubelet API
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # DNS (TCP)
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # DNS (UDP)
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  # Exposing Sonarqube Application
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "gitlab-runner-sg"
  }
}

# Create EC2 Instance
resource "aws_instance" "gitlab_runner" {
  ami           = "ami-0866a3c8686eaeeba" # Ubuntu 24.04 LTS AMI ID
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.gitlab_subnet.id

  vpc_security_group_ids = [aws_security_group.gitlab_runner_sg.id]
  key_name               = "test-key-1024" #This key pair was manually created from the AWS console
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 60
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "gitlab-ec2-runner-root-volume"
    }
  }

  user_data = <<-EOF
              #!/bin/bash
              # Update system
              apt-get update
              apt-get upgrade -y

              # Install required packages
              apt-get install -y curl

              # Install GitLab Runner
              curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | bash
              apt-get install -y gitlab-runner

              # Register the runner (replace with your registration token and GitLab URL)
              gitlab-runner register \
                --non-interactive \
                --url "https://gitlab.com/" \
                --registration-token "glrt-t3_45WN8HAeAw2gVx6Wis-a" \
                --executor "shell" \
                --description "EC2 runner to run Java apps" \
                --tag-list "aws,ec2,dedicated-runner" \
                --run-untagged="true" \
                --locked="false"

              # Start the runner
              systemctl enable gitlab-runner
              systemctl start gitlab-runner

              # Add Docker's official GPG key:
              sudo apt-get update
              sudo apt-get install ca-certificates curl
              sudo install -m 0755 -d /etc/apt/keyrings
              sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
              sudo chmod a+r /etc/apt/keyrings/docker.asc

              # Add the repository to Apt sources:
              echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
                $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
                sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
              sudo apt-get update

              # Install the Docker packages.
              sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

              # Give the right permissions to use docker
              sudo usermod -aG docker ubuntu 
              sudo chmod 666 /var/run/docker.sock
              
              # Run and expose sonarqube on the browser
              docker run -dit --name sonarqube -p 9000:9000 sonarqube:lts-community
              EOF

  tags = {
    Name = "gitlab-runner"
  }
}

# Output the public IP of the gitlab_runner
output "gitlab_runner_public_ip" {
  value = aws_instance.gitlab_runner.public_ip
}

# Output the URL of the Sonarqube Server
output "Sonarqube_url" {
  value = "http://${aws_instance.gitlab_runner.public_ip}:9000"
}

# Output the ssh connection to access the EC2 Runner
output "ssh_connection_to_access_EC2_Runner" {
  value = "ssh -i test-key-1024.pem ubuntu@${aws_instance.gitlab_runner.public_ip}"
}

