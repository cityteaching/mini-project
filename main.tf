#Before you get started create a key pair on your AWS account

provider "aws" {
  region  = "us-east-1"
  access_key = #use your own access key 
  secret_key = #use your own secret key 
}

# 1. create vpc (Virtual privagte cloud)

resource "aws_vpc" "first-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "production"
  }
}
# 2. Internet gateway 

#
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.first-vpc.id

 

  }


# 3.Create custom route table ()

resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.first-vpc.id

  route {
    cidr_block = "0.0.0.0/0" #creating a default route 
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  
}


# 4. Create a subnet

resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.first-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone =  "us-east-1a"  #incase data center goes down use a different data center within same regin  

  tags = {
    Name = "prod-subnet"
  }
}

# 5. Associate subnet with route table #link them

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.prod-route-table.id
}

# 6. Create security group to allow port 22,80,443

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.first-vpc.id

#Create a ingress for each port 
  ingress {
    description      = "HTTPS" 
    from_port        = 443
    to_port          = 443 
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
   
  }


  ingress {
    description      = "HTTPS" 
    from_port        = 80
    to_port          = 80 
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
   
  }

  ingress {
    description      = "SSH" 
    from_port        = 22
    to_port          = 22 
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  
  }
#
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

# 7. Create a network inferface with an ip in the subnet 
#This created a private ip address for the host to access

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

  
  }



# 8. Assign an elastic IP to the network interface creataed in step 7  

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw] 
}


#9. Create Ubuntu server and install / enable apache 2

resource "aws_instance" "web_server_instance" {
    ami = "ami-052efd3df9dad4825"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "main-key"

    network_interface  {
        device_index = 0
        network_interface_id = aws_network_interface.web-server-nic.id



    }

       
   #user_data = <<- EOF
                #!/bin/bash
    #            sudo apt update -y
   #             sud apt install apache2 -y
   #             sudo systemctl start apache2
   #             sud bash -c "echo your very first web server > /var/www/html/index.html"
   #            EOF
  
}














