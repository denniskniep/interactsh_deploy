terraform {
  required_providers {
    aws = {
      source  = "registry.terraform.io/hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  region = "eu-central-1"
}

variable "public_ip" {
  type = string
  default=""
}

variable "domain" {
  type = string
}

variable "interactsh_access_token" {
  type = string
}

variable "interactsh_version" {
  type = string
  default="latest"
}

variable "godaddy_access_token" {
  type = string
  default=""
}

variable "godaddy_ns1" {
  type = string
  default=""
}

variable "godaddy_ns2" {
  type = string
  default=""
}

variable "aws_ssh_key_tag" {
  type = string
  default = "tag:InteractSh"
}

locals {
  cidr_ipv4_allow_all = "0.0.0.0/0"
  cidr_ipv6_allow_all = "::/0"
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_security_group" "basic_interactsh" {
  name        = "basic_interactsh"
  description = "Allow inbound traffic for Interactsh Server"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    description      = "SSH from Anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [local.cidr_ipv4_allow_all]
    ipv6_cidr_blocks = [local.cidr_ipv6_allow_all]
  }

  ingress {
    description      = "HTTPS from Anywhere"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [local.cidr_ipv4_allow_all]
    ipv6_cidr_blocks = [local.cidr_ipv6_allow_all]
  }

  ingress {
    description      = "HTTP from Anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [local.cidr_ipv4_allow_all]
    ipv6_cidr_blocks = [local.cidr_ipv6_allow_all]
  }

  ingress {
    description      = "DNS/tcp from Anywhere"
    from_port        = 53
    to_port          = 53
    protocol         = "tcp"
    cidr_blocks      = [local.cidr_ipv4_allow_all]
    ipv6_cidr_blocks = [local.cidr_ipv6_allow_all]
  }

  ingress {
    description      = "DNS/udp from Anywhere"
    from_port        = 53
    to_port          = 53
    protocol         = "udp"
    cidr_blocks      = [local.cidr_ipv4_allow_all]
    ipv6_cidr_blocks = [local.cidr_ipv6_allow_all]
  }

  ingress {
    description      = "LDAP from Anywhere"
    from_port        = 389
    to_port          = 389
    protocol         = "tcp"
    cidr_blocks      = [local.cidr_ipv4_allow_all]
    ipv6_cidr_blocks = [local.cidr_ipv6_allow_all]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [local.cidr_ipv4_allow_all]
    ipv6_cidr_blocks = [local.cidr_ipv6_allow_all]
  }

  tags = {
    Name = "basic_interactsh"
  }
}

data "aws_key_pair" "maintainer" {
  filter {
    name   = var.aws_ssh_key_tag
    values = [""]
  }
}

resource "aws_instance" "interactsh" {
  ami           = "ami-0a49b025fffbbdac6" # Ubuntu
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.basic_interactsh.id]
  key_name = data.aws_key_pair.maintainer.key_name
  tags = {
    Name = "InteractshServerInstance"
    Type = "InteractshServer"
  }

  # Output on EC2: cat /var/log/cloud-init-output.log
  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update

    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update

    sudo apt-get install -y docker-ce docker-ce-cli containerd.io

    docker --version

    export PUBLIC_IPV4=${var.public_ip}
    if [ -z "$PUBLIC_IPV4" ]; then      
      export PUBLIC_IPV4=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
      echo "No public ip specified, using public ip: $PUBLIC_IPV4"
    fi
    
    export LOCAL_IPV4=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

    if [ "${var.godaddy_access_token}" ]; then
      echo "godaddy access token found; Setting public ip to NS Servers: $PUBLIC_IPV4"      
      curl -X PUT -H 'Authorization: sso-key ${var.godaddy_access_token}' 'https://api.godaddy.com/v1/domains/${var.godaddy_ns1}' -d "[{\"data\":\"$PUBLIC_IPV4\"}]" -H "Content-Type: application/json"           
      curl -X PUT -H 'Authorization: sso-key ${var.godaddy_access_token}' 'https://api.godaddy.com/v1/domains/${var.godaddy_ns2}' -d "[{\"data\":\"$PUBLIC_IPV4\"}]" -H "Content-Type: application/json"      
    fi
    
    sudo docker run -d --name interactsh -p $LOCAL_IPV4:80:80 -p $LOCAL_IPV4:443:443 -p $LOCAL_IPV4:53:53 -p $LOCAL_IPV4:53:53/udp projectdiscovery/interactsh-server:${var.interactsh_version} -token '${var.interactsh_access_token}' -domain '${var.domain}' -ip $PUBLIC_IPV4 -root-tld  -origin-url 'http://localhost:3000' -eviction 30 -hostmaster 'admin@${var.domain}'
  EOF

}

output "public_ip" {
  value = aws_instance.interactsh.*.public_ip
}

output "private_ip" {
  value = aws_instance.interactsh.*.private_ip
}

output "interactsh_access_token" {
  value = var.interactsh_access_token
}