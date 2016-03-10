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
  tags {
     Name = "swarm-master"
  }
  subnet_id = "${aws_subnet.default.id}"
  availability_zone = "us-east-1c"
  key_name = "ami-creation"
  vpc_security_group_ids = ["${aws_security_group.ssh.id}", "${aws_vpc.default.default_security_group_id}"]
  provisioner "remote-exec" {
    inline = [
      "sleep 30 && docker run -d -p 4000:4000 swarm manage -H :4000  --advertise ${aws_instance.swarm-master.private_ip}:4000 consul://${aws_instance.consul.private_ip}:8500"
    ]
    connection {
      user = "ubuntu"
      private_key = "~/.ssh/ami-creation.pem"
    }
  }
}

# Create swarm-node-1
resource "aws_instance" "swarm-node-1" {
  ami = "ami-a75354cd"
  instance_type = "t1.micro"
  tags {
     Name = "swarm-node-1"
  }
  subnet_id = "${aws_subnet.default.id}"
  availability_zone = "us-east-1c"
  key_name = "ami-creation"
  vpc_security_group_ids = ["${aws_security_group.ssh.id}", "${aws_vpc.default.default_security_group_id}"]
  provisioner "remote-exec" {
    inline = [
      "sleep 30 && docker run -d swarm join --advertise=${aws_instance.swarm-node-1.private_ip}:2375 consul://${aws_instance.consul.private_ip}:8500"
    ]
    connection {
      user = "ubuntu"
      private_key = "~/.ssh/ami-creation.pem"
    }
  }
  depends_on = ["aws_instance.swarm-master"]
}

# Create swarm-node-2
resource "aws_instance" "swarm-node-2" {
  ami = "ami-a75354cd"
  instance_type = "t1.micro"
  tags {
     Name = "swarm-node-2"
  }
  subnet_id = "${aws_subnet.default.id}"
  availability_zone = "us-east-1c"
  key_name = "ami-creation"
  vpc_security_group_ids = ["${aws_security_group.ssh.id}", "${aws_vpc.default.default_security_group_id}"]
  provisioner "remote-exec" {
    inline = [
      "sleep 30 && docker run -d swarm join --advertise=${aws_instance.swarm-node-2.private_ip}:2375 consul://${aws_instance.consul.private_ip}:8500"
    ]
    connection {
      user = "ubuntu"
      private_key = "~/.ssh/ami-creation.pem"
    }
  }
  depends_on = ["aws_instance.swarm-master"]
}  

# Create swarm-node-3
resource "aws_instance" "swarm-node-3" {
  ami = "ami-a75354cd"
  instance_type = "t1.micro"
  tags {
     Name = "swarm-node-3"
  }
  subnet_id = "${aws_subnet.default.id}"
  availability_zone = "us-east-1c"
  key_name = "ami-creation"
  vpc_security_group_ids = ["${aws_security_group.ssh.id}", "${aws_vpc.default.default_security_group_id}"]
  provisioner "remote-exec" {
    inline = [
      "sleep 30 && docker run -d swarm join --advertise=${aws_instance.swarm-node-3.private_ip}:2375 consul://${aws_instance.consul.private_ip}:8500"
    ]
    connection {
      user = "ubuntu"
      private_key = "~/.ssh/ami-creation.pem"
    }
  }
  depends_on = ["aws_instance.swarm-master"]
}

# Create swarm-node-4
resource "aws_instance" "swarm-node-4" {
  ami = "ami-a75354cd"
  instance_type = "t1.micro"
  tags {
     Name = "swarm-node-4"
  }
  subnet_id = "${aws_subnet.default.id}"
  availability_zone = "us-east-1c"
  key_name = "ami-creation"
  vpc_security_group_ids = ["${aws_security_group.ssh.id}", "${aws_vpc.default.default_security_group_id}"]
  provisioner "remote-exec" {
    inline = [
      "sleep 30 && docker run -d swarm join --advertise=${aws_instance.swarm-node-4.private_ip}:2375 consul://${aws_instance.consul.private_ip}:8500"
    ]
    connection {
      user = "ubuntu"
      private_key = "~/.ssh/ami-creation.pem"
    }
  }
  depends_on = ["aws_instance.swarm-master"]
}

# Create a consul node
resource "aws_instance" "consul" {
  ami = "ami-a75354cd"
  instance_type = "t1.micro"
  tags {
     Name = "consul"
  }
  subnet_id = "${aws_subnet.default.id}"
  availability_zone = "us-east-1c"
  key_name = "ami-creation"
  vpc_security_group_ids = ["${aws_security_group.ssh.id}", "${aws_vpc.default.default_security_group_id}"]
  provisioner "remote-exec" {
    inline = [
      "sleep 30 && docker run -d -p 8500:8500 --name=consul progrium/consul -server -bootstrap"
    ]
    connection {
      user = "ubuntu"
      private_key = "~/.ssh/ami-creation.pem"
    }
  }
}
