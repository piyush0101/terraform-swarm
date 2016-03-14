# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

# Create a security group for ssh access
resource "aws_security_group" "ssh" {
  name = "ssh_access"
  description = "Allow ssh access from anywhere"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id = "${aws_vpc.default.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1c"
}

# Create docker-swarm master
resource "aws_instance" "swarm-master" {
  ami = "ami-a75354cd"
  instance_type = "t1.micro"
  subnet_id = "${aws_subnet.default.id}"
  availability_zone = "us-east-1c"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.ssh.id}", "${aws_vpc.default.default_security_group_id}"]

  tags {
     Name = "swarm-master"
  }

  connection {
     user = "${var.user}"
     private_key = "${var.key_path}"
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 30 && docker run -d -p 4000:4000 swarm manage -H :4000  --advertise ${aws_instance.swarm-master.private_ip}:4000 consul://${aws_instance.consul.private_ip}:8500"
    ]
  }
}

# Create swarm nodes
resource "aws_instance" "swarm-node" {
  ami = "ami-a75354cd"
  instance_type = "t1.micro"
  subnet_id = "${aws_subnet.default.id}"
  availability_zone = "us-east-1c"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.ssh.id}", "${aws_vpc.default.default_security_group_id}"]
  count = "${var.nodes}"

  tags {
     Name = "swarm-node-${count.index}"
  }
  

  connection {
      user = "${var.user}"
      private_key = "${var.key_path}"
  }
  
  provisioner "remote-exec" {
    inline = [
      "sleep 30 && docker run -d swarm join --advertise=${self.private_ip}:2375 consul://${aws_instance.consul.private_ip}:8500"
    ]
  }
  
  depends_on = ["aws_instance.swarm-master"]
}

# Create a consul node
resource "aws_instance" "consul" {
  ami = "ami-a75354cd"
  instance_type = "t1.micro"
  subnet_id = "${aws_subnet.default.id}"
  availability_zone = "us-east-1c"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.ssh.id}", "${aws_vpc.default.default_security_group_id}"]

  tags {
     Name = "consul"
  }
  
  connection {
      user = "${var.user}"
      private_key = "${var.key_path}"
  }
    
  provisioner "remote-exec" {
    inline = [
      "sleep 30 && docker run -d -p 8500:8500 --name=consul progrium/consul -server -bootstrap"
    ]
  }
}
