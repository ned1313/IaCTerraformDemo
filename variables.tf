variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "aws_region" {
  default = "us-east-1"
}

variable "amis" {
  type = "map"

  default = {
    us-east-1 = "ami-13be557e"
    us-west-2 = "ami-06b94666"
  }
}

variable "naming_prefix" {
  default = "NewsletterTest"
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

variable "client_password" {}

variable "my_public_ip" {}
