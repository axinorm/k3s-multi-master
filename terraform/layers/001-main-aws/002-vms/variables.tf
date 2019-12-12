variable "group" {}
variable "env" {}
variable "region" {}
variable "vpc_cidr" {}

variable "instance_type" {
  default = "t2.micro"
}

variable "instance_type_master" {
  default = "t2.medium"
}

data "aws_ami" "debian" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-10-amd64-*"]
  }

  owners = ["136693071363"]
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "${var.group}-${var.env}-${var.region}-tfstate"
    key    = "001-vpc.tfstate"
    region = var.region
  }
}
