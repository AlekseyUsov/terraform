variable "amis" {
  type    = "map"
  default = {
    "us-east-1" = "ami-6871a115"
    "us-east-2" = "ami-03291866"
  }
}

variable "region" {
  default = "us-east-2"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "zones" {
  default = ["a", "b", "c"]
}

variable "private_key" {
  default = "~/.ssh/ausov.pem"
}

variable "username" {
  default = "ec2-user"
}
