provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "test" {
  cidr_block = "${var.network_address_space}"

  tags = {
    Name = "${var.naming_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "test" {
  vpc_id = "${aws_vpc.test.id}"

  tags = {
    Name = "${var.naming_prefix}-ig"
  }
}

resource "aws_subnet" "test1" {
  cidr_block        = "${var.subnet1_address_space}"
  vpc_id            = "${aws_vpc.test.id}"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"

  tags = {
    Name = "${var.naming_prefix}-subnet1"
  }
}

resource "aws_subnet" "test2" {
  cidr_block        = "${var.subnet2_address_space}"
  vpc_id            = "${aws_vpc.test.id}"
  availability_zone = "${data.aws_availability_zones.available.names[1]}"

  tags = {
    Name = "${var.naming_prefix}-subnet2"
  }
}

resource "aws_route_table" "test" {
  vpc_id = "${aws_vpc.test.id}"
}

resource "aws_route_table_association" "test1" {
  subnet_id      = "${aws_subnet.test1.id}"
  route_table_id = "${aws_route_table.test.id}"
}

resource "aws_route_table_association" "test2" {
  subnet_id      = "${aws_subnet.test2.id}"
  route_table_id = "${aws_route_table.test.id}"
}

resource "aws_security_group" "elb" {
  name        = "test_elb"
  description = "used for Pluralsight demo"
  vpc_id      = "${aws_vpc.test.id}"

  #Allow HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Default security group 
resource "aws_security_group" "default" {
  name        = "test_sg"
  description = "Used for Pluralsight demo"
  vpc_id      = "${aws_vpc.test.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.network_address_space}"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "web" {
  name = "test-elb"

  subnets         = ["${aws_subnet.test1.id}", "${aws_subnet.test2.id}"]
  security_groups = ["${aws_security_group.elb.id}"]
  instances       = ["${aws_instance.example.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}

resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

resource "aws_instance" "example" {
  ami           = "${lookup(var.amis, var.aws_region)}"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.test1.id}"
  key_name      = "${aws_key_pair.auth.id}"

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install nginx",
      "sudo service nginx start",
    ]
  }

  tags = {
    Name = "${var.naming_prefix}-client1"
  }
}

resource "aws_eip" "ip" {
  instance = "${aws_instance.example.id}"
}

output "aws_public_ip" {
  value = "${aws_eip.ip.public_ip}"
}
