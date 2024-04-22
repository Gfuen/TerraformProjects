terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.67.0"
      
    }

  }
  
}

# AWS provider with default region and profile
provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

# VPC test-env
resource "aws_vpc" "test-env" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
}

# Internet Gateway
resource "aws_internet_gateway" "ig" {
  vpc_id = "${aws_vpc.test-env.id}"
}


# Subnet uno
resource "aws_subnet" "subnet-uno" {
  cidr_block = "${cidrsubnet(aws_vpc.test-env.cidr_block, 3, 1)}"
  vpc_id = "${aws_vpc.test-env.id}"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

#Call whatismyip
data "external" "whatismyip" {
  program = ["/bin/bash" , "${path.module}/whatismyip.sh"]
}

# security group for SSH access
resource "aws_security_group" "ingress-test" {
  name = "allow-all-sg"
  vpc_id = "${aws_vpc.test-env.id}"
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }# Terraform removes the default rule
  egress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }
}

# Routing table for public subnet 
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.test-env.id}"
}
resource "aws_route" "public_internet_gateway" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.ig.id}"
}

# Route table associations 
resource "aws_route_table_association" "public" {
  subnet_id = "${aws_subnet.subnet-uno.id}"
  route_table_id = "${aws_route_table.public.id}"
}

# Create a security group allowing inbound HTTP access from a browser-based client
resource "aws_security_group" "https_security_group" {
  name        = "allow-http-from-browser"
  description = "Allow inbound HTTPS traffic from a browser-based client"
  vpc_id = "${aws_vpc.test-env.id}"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open to the world, consider restricting to a specific IP range
  }

  # Allow outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Bug Bounty EC2 instance
resource "aws_instance" "example_server" {

  ami           = "ami-0e001c9271cf7f3b9"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  key_name = "KeyPair1"
  security_groups = [
    "${aws_security_group.ingress-test.id}",
    "${aws_security_group.https_security_group.id}"
  ]
  subnet_id = "${aws_subnet.subnet-uno.id}"

  tags = {
    Name = "GfuenExample"
  }
  user_data     = <<-EOF
  #!/bin/bash
  apt update -y
  apt install nmap -y
  apt install xterm -y
  apt install -y python3-pip
  apt install -y python3-venv
  python3 -m pip install pipx
  python3 -m pipx ensurepath
  apt install -y vim
  apt install -y dos2unix
  apt install -y rlwrap
  apt install -y gnome-screenshot
  apt install -y golang
  apt install -y xclip
  apt install -y cmake
  apt install -y grc
  apt install -y awscli
  apt install -y build-essential
  apt install -y gcc 
  apt install -y git
  apt install -y wget 
  apt install -y curl
  apt install -y inetutils-ping 
  apt install -y make 
  apt install -y nmap 
  apt install -y whois 
  apt install -y perl 
  apt install -y nikto
  apt install -y dnsutils 
  apt install -y net-tools
  apt install -y tmux
  apt install -y feroxbuster
  apt install fcrackzip
  apt install exa
  EOF
    # EC2 Instance Connect configuration
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
  }
}