# Provider
provider "aws" {
  region = var.region
}

# Create VPC
resource "aws_vpc" "legacy" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "legacyvpc"
    }
}

# Create Internet Gateway
resource "aws_internet_gateway" "legacygw" {
  vpc_id = aws_vpc.legacy.id

  tags = {
    Name = "myigw"
  }
}

# Create Route Table
resource "aws_route_table" "legacyRT" {
  vpc_id = aws_vpc.legacy.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.legacygw.id
      }

  tags = {
    Name = "myRT"
  }
}

#create Subnets
resource "aws_subnet" "legacysubnet" {
  vpc_id     = aws_vpc.legacy.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "publicsubnet"
  }
}


# Subnet Route Table Association
resource "aws_route_table_association" "routeTA" {
  subnet_id      = aws_subnet.legacysubnet.id
  route_table_id = aws_route_table.legacyRT.id
}

# Create Security Group
resource "aws_security_group" "legacySG" {
  name        = "allow_tls"
  description = "Allow legacySG-traffic"
  vpc_id      = aws_vpc.legacy.id

/*
dynamic "ingress" {
iterator = port
for_each = var.ingressrules
content {
from_port = port.value
to_port = port.value
protocol = "tcp"
cidr_blocks = ["0.0.0.0/16"]
}
}

dynamic "egress" {
iterator = port
for_each = var.egressrules
content {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}
}*/

tags = {
    Name = "mySG"
    
}

ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
}
  ingress {
    description      = "TLS from VPC"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.legacy.cidr_block]
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = ["::/0"]
  }
}

# Create Network Interface with an Elastic IP in the Subnet
  resource "aws_network_interface" "legacyNE" {
  subnet_id       = aws_subnet.legacysubnet.id
 # private_ips     = ["10.0.1.50","10.0.2.50","10.0.3.50"]
  security_groups = [aws_security_group.legacySG.id]

  # Do not use network_interface to associate the EIP to aws_lb or aws_nat_gateway resources.
  # Instead use the allocation_id available in those resources to allow AWS to manage the association, 
  # otherwise you will see AuthFailure errors.
   tags = {
    Name = "mynetworkI"
  }
  }
# create Elastic IP
  resource "aws_eip" "legacyEIP" {
      network_interface = aws_network_interface.legacyNE.id
      vpc = true
      #associate_with_private_ip = ["10.0.1.50","10.0.2.50","10.0.3.50"]
      depends_on = [aws_internet_gateway.legacygw]
      # EIP may require IGW to exist prior to association. 
      # Use depends_on to set an explicit dependency on the IGW.
  }
  

  resource "aws_instance" "ubuntuServers2" {
      ami = var.ami
      instance_type = var.instance_type
      key_name = var.key_name  

     # availability_zone =  "" 
 network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.legacyNE.id
  }
     user_data = <<-E0F
     #!/bin/bash
sudo apt update –y 
sudo useradd ansible -m
echo "ansible ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ansible  -y
# sudo su - ansible
sudo apt-add-repository ppa:ansible/ansible -y
sudo apt install ansible -y
sudo apt update -y
sudo chown -R ansible:ansible /etc/ansible
E0F

tags = {
         Name = "ansible"
     }
  }
