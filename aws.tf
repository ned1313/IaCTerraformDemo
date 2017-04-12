##################################################################################
# PROVIDERS
##################################################################################
#Define a provider for AWS
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

#Collect data for AZs
data "aws_availability_zones" "available" {}

##################################################################################
# RESOURCES
##################################################################################

########################## NETWORK ###############################################
#Create the VPC
resource "aws_vpc" "test" {
  cidr_block = "${var.network_address_space}"

  tags {
    Name = "${var.naming_prefix}-vpc"
  }
}

#Create an internet gateway for egress
resource "aws_internet_gateway" "test" {
  vpc_id = "${aws_vpc.test.id}"

  tags {
    Name = "${var.naming_prefix}-ig"
  }
}

#Establish a subnet in the first availability zone
resource "aws_subnet" "test1" {
  cidr_block              = "${var.subnet1_address_space}"
  vpc_id                  = "${aws_vpc.test.id}"
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"
  map_public_ip_on_launch = true

  tags {
    Name = "${var.naming_prefix}-subnet1"
  }
}

#Establish a subnet in the second availability zone
resource "aws_subnet" "test2" {
  cidr_block              = "${var.subnet2_address_space}"
  vpc_id                  = "${aws_vpc.test.id}"
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"
  map_public_ip_on_launch = true

  tags {
    Name = "${var.naming_prefix}-subnet2"
  }
}

#Create a route table to define routing for the subnets
resource "aws_route_table" "test" {
  vpc_id = "${aws_vpc.test.id}"

  tags {
    Name = "${var.naming_prefix}-drt"
  }
}

#Add a default route for internet traffic
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_route_table.test.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.test.id}"
}

#Associate the subnets with the route table
resource "aws_route_table_association" "test1" {
  subnet_id      = "${aws_subnet.test1.id}"
  route_table_id = "${aws_route_table.test.id}"
}

resource "aws_route_table_association" "test2" {
  subnet_id      = "${aws_subnet.test2.id}"
  route_table_id = "${aws_route_table.test.id}"
}

#Create an elastice load balancer security group allowing inbound HTTP
resource "aws_security_group" "elb" {
  name        = "test-elb"
  description = "used for Pluralsight demo"
  vpc_id      = "${aws_vpc.test.id}"

  #Allow HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.naming_prefix}-elbsg"
  }
}

#Create a default security group to allow remote configuration of VM
resource "aws_security_group" "instance" {
  name        = "test-sg"
  description = "Used for Pluralsight demo"
  vpc_id      = "${aws_vpc.test.id}"

  #Allow SSH access from anywhere (this can be restricted to local IP Address)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Allow HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.network_address_space}"]
  }

  #Allow outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.naming_prefix}-dsg"
  }
}

########################## ELB ###################################################

#Create an elastic load balancer to front-end the web server
resource "aws_elb" "web" {
  name = "test-elb"

  subnets         = ["${aws_subnet.test1.id}", "${aws_subnet.test2.id}"]
  security_groups = ["${aws_security_group.elb.id}"]
  instances       = ["${aws_instance.web.id}"]

  #Listen on port 80 for HTTP traffic
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  tags {
    Name = "${var.naming_prefix}-elb"
  }
}

########################## INSTANCES #############################################

##Create an EC2 instance for the Web server
resource "aws_instance" "web" {
  ami             = "${lookup(var.amis, var.aws_region)}"
  instance_type   = "t2.small"
  subnet_id       = "${aws_subnet.test1.id}"
  key_name        = "${var.key_name}"
  security_groups = ["${aws_security_group.instance.id}"]

  connection {
    user        = "ec2-user"
    private_key = "${file(var.private_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install nginx -y",
      "sudo service nginx start",
    ]
  }

  tags {
    Name = "${var.naming_prefix}-web1"
  }
}

#Create an EC2 instance for the Database server
resource "aws_instance" "db" {
  ami             = "${lookup(var.amis, var.aws_region)}"
  instance_type   = "t2.small"
  subnet_id       = "${aws_subnet.test1.id}"
  key_name        = "${var.key_name}"
  security_groups = ["${aws_security_group.instance.id}"]

  connection {
    user        = "ec2-user"
    private_key = "${file(var.private_key_path)}"
  }

  tags {
    Name = "${var.naming_prefix}-db1"
  }
}

##################################################################################
# OUTPUTS
##################################################################################

output "aws_elb_dns" {
  value = "${aws_elb.web.dns_name}"
}
