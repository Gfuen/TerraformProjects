terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

resource "aws_instance" "example_server" {
  ami           = "ami-0ff8a91507f77f867"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  key_name = "KeyPair1"

  tags = {
    Name = "GfuenExample"
  }
}