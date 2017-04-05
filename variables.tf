variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "aws_region" {
  default = "us-east-1"
}

variable "amis" {
  type = "map"

  default = {
    us-east-1 = "ami-6869aa05"
    us-west-2 = "ami-7172b611"
  }
}

variable "naming_prefix" {
  default = "IaCDemo"
}

variable "network_address_space" {
  default = "10.0.0.0/16"
}

variable "subnet1_address_space" {
  default = "10.0.0.0/24"
}

variable "subnet2_address_space" {
  default = "10.0.1.0/24"
}

variable "client_username" {
  default = "nedadmin"
}

variable "key_name" {
  default = "nbellavance"
}

variable "client_password" {}

variable "my_public_ip" {}

variable "private_key_path" {}
