provider "aws" {
  region     = "ap-south-1"
  access_key = "xxx"
  secret_key = "xxx"
}
resource "aws_vpc" "customvpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Custom vpc"
  }
}
resource "aws_internet_gateway" "custominternetgateway" {
  vpc_id = aws_vpc.customvpc.id
}
resource "aws_subnet" "websubnet" {
  cidr_block        = "10.0.0.0/20"
  vpc_id            = aws_vpc.customvpc.id
  availability_zone = "ap-south-1a"
}
resource "aws_subnet" "appsubnet" {
  cidr_block        = "10.0.16.0/20"
  vpc_id            = aws_vpc.customvpc.id
  availability_zone = "ap-south-1b"
}
resource "aws_subnet" "dbsubnet" {
  cidr_block        = "10.0.32.0/20"
  vpc_id            = aws_vpc.customvpc.id
  availability_zone = "ap-south-1a"
}
resource "aws_route_table" "publicrt" {
  vpc_id = aws_vpc.customvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.custominternetgateway.id
  }
}
resource "aws_route_table" "pvtrt" {
  vpc_id = aws_vpc.customvpc.id
}
resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.websubnet.id
  route_table_id = aws_route_table.publicrt.id
}
resource "aws_route_table_association" "pvt_association" {
  subnet_id      = aws_subnet.appsubnet.id
  route_table_id = aws_route_table.pvtrt.id
}
resource "aws_route_table_association" "db_association" {
  subnet_id      = aws_subnet.dbsubnet.id
  route_table_id = aws_route_table.pvtrt.id
}


resource "aws_instance" "webec2" {
  ami                    = "ami-0d81306eddc614a45"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.websg.id]
  key_name               = "tf-key-pair"
  subnet_id = aws_subnet.websubnet.id
  tags = {
    Name = "web"
  }
}
resource "aws_instance" "appec2" {
  ami                    = "ami-0d81306eddc614a45"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.appsg.id]
  key_name  = "tf-key-pair"
  subnet_id = aws_subnet.appsubnet.id
  tags = {
    Name = "app"
  }
}
resource "aws_db_instance" "rds" {
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  username               = "root"
  password               = "Pass1234"
  vpc_security_group_ids = [aws_security_group.dbsg.id]
  identifier             = "myrds"
  db_subnet_group_name   = aws_db_subnet_group.mydbsubnetgroup.id
}
resource "aws_db_subnet_group" "mydbsubnetgroup" {
  name        = "mydbsubnetgroup"
  subnet_ids  = [aws_subnet.dbsubnet.id, aws_subnet.appsubnet.id]
  description = "db subnet group"
}



resource "aws_security_group" "websg" {
  name   = "web-sg"
  vpc_id = aws_vpc.customvpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "appsg" {
  name   = "app-sg"
  vpc_id = aws_vpc.customvpc.id
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/20"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "dbsg" {
  name   = "db-sg"
  vpc_id = aws_vpc.customvpc.id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.16.0/20"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "tf-key-pair" {
  key_name   = "tf-key-pair"
  public_key = tls_private_key.rsa.public_key_openssh
}
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "local_file" "tf-key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "tf-key-pair"
}
