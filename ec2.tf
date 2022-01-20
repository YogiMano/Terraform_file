terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}
resource "aws_instance" "myec2" {
    ami = "ami-0af25d0df86db00c1"
    instance_type = "t2.micro"
}
