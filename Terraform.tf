provider "aws" {
   access_key = "xxxxxxxx"
   secret_key = "xxxxxxxx"
   region = "ap-south-1"
}

#creating key
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "generated_key" {
   public_key = "${tls_private_key.example.public_key_openssh}"
}

#creating a vpc
resource "aws_vpc" "main" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}

#public subnet
resource "aws_subnet" "wordpresssubnet" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "192.168.1.0/24"
  map_public_ip_on_launch="true"
  availability_zone= "ap-south-1a"
  tags = {
    Name = "wordpresssubnet"
  }
}

#private subnet
resource "aws_subnet" "mysqlsubnet" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "192.168.2.0/24"
  map_public_ip_on_launch="false"
  availability_zone="ap-south-1b"
  tags = {
    Name = "mysqlsubnet"
  }
}

#creating internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "main"
  }
}

#creating routing table
resource "aws_route_table" "r" {
  vpc_id = "${aws_vpc.main.id}"
  
 tags = {
    Name = "main"
  }
}

#associating routing table with wordpresssubnet
resource "aws_route_table_association" "alpha" {
  subnet_id      = aws_subnet.wordpresssubnet.id
  route_table_id = aws_route_table.r.id
}
resource "aws_route" "beta" {
  route_table_id            = aws_route_table.r.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.gw.id
  depends_on                = ["aws_route_table.r"]
}

#creating security group for wordpresssubnet
resource "aws_security_group" "allow_tlsp" {
  name        = "allow_tlsp"
  vpc_id      = "${aws_vpc.main.id}"
  description = "Allow TLS inbound traffic"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }


  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

   egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_tlsp"
  }
}


#creating security group for mysqlsubnet
resource "aws_security_group" "allow_tlsp2" {
  name        = "allow_tlsp2"
  vpc_id      = "${aws_vpc.main.id}"
  description = "Allow TLS inbound traffic"

 ingress {
    description = "Mysql Protocol"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }


   egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_tlsp2"
  }
}

#creating aws wordpress instance
resource "aws_instance" "wordpress" {
  ami   ="ami-004a955bfb611bf13"
  instance_type = "t2.micro"
  key_name="${aws_key_pair.generated_key.key_name}"
  vpc_security_group_ids = ["${aws_security_group.allow_tlsp.id}"]
  subnet_id =aws_subnet.wordpresssubnet.id
 tags = {
    Name = "Myfirstos-wordpress"
  }
}

#creating aws mysql instance
resource "aws_instance" "mysql" {
 ami   ="ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  key_name="${aws_key_pair.generated_key.key_name}"
  vpc_security_group_ids = ["${aws_security_group.allow_tlsp2.id}"]
  subnet_id=aws_subnet.mysqlsubnet.id
 tags = {
    Name = "Myfirstos-mysql"
  }
}
