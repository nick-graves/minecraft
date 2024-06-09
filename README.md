# CS312 Course Project Part 2

## Table of Contentes
- [Overview](#Overview)
- [Tutorial](#Tutorial)
  - [Update AWS Credentials](#Update-AWS-Credentials)
  - [Executing Terraform Script](#Executing-Terraform-Script)
  - [Logging into the server](#Logging-into-the-server)
- [Explanation](#Explanation)
  - [Terraform](#Terraform)

# Overview
This repo serves as a way to automatically deploy a public Minecraft server with one simple command. This will require an AWS account (I'm using AWS learners lab), terraform install on your local computer and this GitHub repo. This file includes steps to deploy the server along with a description of the code that makes it possible. 

# Tutorial

## Update AWS Credentials
To execute this you will need to update your local copy of your AWS credentials.
1. **Open the "Launch AWS Academy Learner Lab" canvas page**.
2. **Click the "AWS Details" button to reveal your AWS credentials**
   - You should see 3 strings: aws_access_key_id, aws_secret_access_key, aws_session_token
3. **Open a PowerShell on your local computer. CD into "~/.aws" This file should contain some dated AWS credentials.**
4. **Delete these credentials and paste in the new ones from step 2**

## Executing Terraform Script
Now that our AWS credentials are correct it is time to execute the terraform script. This will both create your EC2 instance on which the server will be hosted and download all necessary files to the EC2 instance for hosting. 
1. **Within the cloned version of this repo CD into the terraform dir**
   - You should see the following scripts: main.tf, variables.tf, output.tf
3. **First run this command ```terraform init```**
4. **Next run ```terraform apply```**
5. **At the end of the script running you should see the following**
```
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

instance_ip = "xx.xxx.xx.xxx"
```
6. **Take note of the ```instance_ip```**

## Logging into the server
The stage is now set! The last thing to do is test and see if everything is working.
1. **The first option for testing is to launch Minecraft in the version that your server is set for (if you used the provided ```setup-minecraft.sh``` script your version is ```1.20.1```). Then click multiplayer and add server. Name it whatever you please and input the ```instance_ip``` from the previous step as the IP address and connect!**
2. The second option for testing is to use the nmap command. This option only requires you to have the namp service downloaded. Run the following command to test ```nmap -sV -Pn -p T:25565 <instance_public_ip>```**

# Explanation

This repo uses a combination of terraform and bash scripts to create and deploy the Minecraft server. Terraform works to create and configure the EC2 instance and a bash script is used to download everything you need for the server itself. 

## Terraform
Three terraform scripts are used to create/configure the instance and execute the necessary bash scripts. ```main.tf``` is the meat and potatoes of it. 
```
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
```
This section of works configures your region along with creating an EC2 instance that can be used to hold the server. 
```
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
```
This section configures your security group along with your inbound and outbound rules. These rules are what allow you to both connect to the Minecraft server and ssh into the EC2 instance. 
```
provisioner "file" {
    source      = "../scripts/setup-minecraft.sh"
    destination = "/home/ec2-user/setup-minecraft.sh"
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/setup-minecraft.sh",
      "sudo /home/ec2-user/setup-minecraft.sh"
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.private_key_path)
    host        = self.public_ip
  }
}
```
This section grabs the ```setup-minecraft.sh``` script and automatically ssh into the EC2 instance to upload and execute the script. 









