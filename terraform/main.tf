provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "minecraft_server" {
  ami           = "ami-05a6dba9ac2da60cb"
  instance_type = "t4g.small"
  key_name      = var.key_name
  security_groups = [aws_security_group.minecraft.name]
  associate_public_ip_address = true

  tags = {
    Name = "Minecraft Server West"
  }

  user_data = <<-EOF
              #!/bin/bash
              curl -o /home/ec2-user/setup-minecraft.sh https://raw.githubusercontent.com/nick-graves/minecraft/main/scripts/setup-minecraft.sh
              chmod +x /home/ec2-user/setup-minecraft.sh
              /home/ec2-user/setup-minecraft.sh
              EOF
}

resource "aws_security_group" "minecraft" {
  name        = "Minecraft_Security_Group"
  description = "Security group for minecraft server"
  vpc_id      = "vpc-0d7050b9b79c37ac1"

  ingress {
    from_port   = 25565
    to_port     = 25565
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