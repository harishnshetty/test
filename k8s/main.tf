# VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.75.0.0/16"

  tags = {
    Name = "my-vpc"
  }
}

# Public subnet (ensure it assigns public IPs to instances launched in it)
resource "aws_subnet" "public1a" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.75.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1a"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my-igw"
  }
}

# Route Table for public subnets (send 0.0.0.0/0 to IGW)
resource "aws_route_table" "my_rt_public" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "rt-public"
  }

  # ensure IGW exists first (not strictly necessary because reference creates implicit dependency,
  # but kept to be explicit about ordering)
  depends_on = [aws_internet_gateway.igw]
}

# Associate the route table with the public subnet
resource "aws_route_table_association" "public1a_assoc" {
  subnet_id      = aws_subnet.public1a.id
  route_table_id = aws_route_table.my_rt_public.id
}

# Security Group allowing SSH and HTTP (attached to the VPC)
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg-1"
  }
}

# EC2 Instance
resource "aws_instance" "test_instance" {
  ami           = "ami-02b8269d5e85954ef" # ensure this AMI is valid in ap-south-1
  instance_type = "t2.micro"
  key_name      = "new-keypair" # must exist in the AWS account/region
  subnet_id     = aws_subnet.public1a.id

  # When launching in a VPC, prefer vpc_security_group_ids
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  associate_public_ip_address = true

  tags = {
    Name = "test-instance"
  }
  depends_on = [aws_vpc.my_vpc]
}

output "instance_public_ip" {
  value = aws_instance.test_instance.public_ip
}