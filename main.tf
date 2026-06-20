terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.31.0"
    }
  }
}

provider "aws" {
  # Configuration options
}

resource "aws_instance" "minikube_ec2" {
  ami           = "ami-0532be01f26a3de55"   # Amazon Linux 2 AMI (update to region-specific)
  instance_type = "m7i-flex.large"
  key_name      = "kube_1"

  vpc_security_group_ids = [aws_security_group.ssh_only.id]

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"  # Recommended for performance and cost efficiency
    delete_on_termination = true  # Cleans up the volume when destroying the infrastructure
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo amazon-linux-extras enable docker
              sudo yum install -y docker
              sudo service docker start
              sudo usermod -aG docker ec2-user
              newgrp docker
              sudo yum install -y git
              sudo yum install -y httpd-tools

              MY_IP=$(curl -s https://checkip.amazonaws.com)
              curl -s "https://www.duckdns.org/update?domains=${var.duckdns_domain}&token=${var.duckdns_token}&ip=$MY_IP"
              
              sudo mkdir -p /usr/local/lib/docker/cli-plugins
              sudo curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
              sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

              mkdir -p /home/ec2-user/.docker/cli-plugins
              curl -L https://github.com/docker/buildx/releases/download/v0.17.1/buildx-v0.17.1.linux-amd64 -o /home/ec2-user/.docker/cli-plugins/docker-buildx
              chmod +x /home/ec2-user/.docker/cli-plugins/docker-buildx  

              git clone https://github.com/clinton-pillay7/odkcentralclone.git /home/ec2-user/central
              cd /home/ec2-user/central
              git submodule update --init --recursive
              chown -R ec2-user:ec2-user /home/ec2-user/central
              touch /home/ec2-user/central/files/allow-postgres14-upgrade
              cp /home/ec2-user/central/.env.template /home/ec2-user/central/.env
              echo 'SERVICE_NODE_OPTIONS='--max-old-space-size=3072'' >> /home/ec2-user/central/.env
              echo DOMAIN=${var.duckdns_domain} >> /home/ec2-user/central/.env
              echo SYSADMIN_EMAIL=${var.sysadmin_email} >> /home/ec2-user/central/.env
              htpasswd -bc /home/ec2-user/central/files/nginx/prometheus.htpasswd admin ${var.prometheus_pass}
              echo GRAFANA_USER=admin >> /home/ec2-user/central/.env
              echo GRAFANA_PASSWORD=${var.grafana_pass} >> /home/ec2-user/central/.env
              
              sudo fallocate -l 2G /swap
              sudo dd if=/dev/zero of=/swap bs=1k count=2048k
              sudo chmod 600 /swap
              sudo mkswap /swap
              sudo swapon /swap
              sudo sysctl -w vm.swappiness=10
              echo '/swapfile none swap sw 0 0' >> /etc/sysctl.conf
              echo '/swap swap swap defaults 0 0' >> /etc/fstab

              chown -R ec2-user:ec2-user /home/ec2-user/.docker
              chown -R ec2-user:ec2-user /home/ec2-user/central
              chmod -R u=rwX,go=rX /home/ec2-user/central
              EOF

  tags = {
    Name = "Terraform-Minikube-EC2"
  }
}

data "aws_vpc" "default" {
  default = true
}

# Create a security group that only allows SSH from anywhere
resource "aws_security_group" "ssh_only" {
  name        = "ssh-only"
  description = "Allow SSH from any IP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "prom"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Output the public IP
output "ec2_public_ip" {
  description = "Public IP of the Minikube EC2 instance"
  value       = aws_instance.minikube_ec2.public_ip
}
