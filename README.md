# CS312 Course Project Part 2

## Table of Contentes
- [Overview](#Overview)
- [Tutorial](#Tutorial)
  - [Update AWS Credentials](#Update-AWS-Credentials)
  - [Executing Scripts](#Executing-Scripts)
  - [Logging into the server](#Logging-into-the-server)
- [Explanation](#Explanation)
  - [Terraform](#Terraform)
  - [Bash](#Bash)
- [Sources](#Sources)

# Overview
This repo serves as a way to automatically deploy a public Minecraft server with one simple command. This will require an AWS account (I'm using AWS learners lab), terraform install on your local computer and this GitHub repo. This file includes steps to deploy the server along with a description of the code that makes it possible. 

# Tutorial

## Update AWS Credentials
To execute this you will need to update your local copy of your AWS credentials.
1. **Open the "Launch AWS Academy Learner Lab" canvas page**
2. **Click the "AWS Details" button to reveal your AWS credentials**
    - You should see 3 strings: aws_access_key_id, aws_secret_access_key, aws_session_token
3. **Open a PowerShell on your local computer. CD into "~/.aws" This file should contain some dated AWS credentials**
4. **Delete these credentials and paste in the new ones from step 2**

## Executing Scripts
Now that our AWS credentials are correct it is time to execute our scripts. This will create a new key pair and update the terraform files with the new key. It will both create your EC2 instance on which the server will be hosted and download all necessary files to the EC2 instance for hosting. 
1. **In the home directory of this repo you will find a script called ```deploy.sh```. As the name would imply this file is responsible for deploying the server. Run the script with this command ```bash deploy.sh```. Just like that you are done all you need to do now is sit back and wait**
    - NOTE: If you run into any errors with the execution of this script try this command to ensure you have proper perms ```chmod +x deploy.sh```
2. **At the end of the script running you should see the following**
```
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

instance_ip = "xx.xxx.xx.xxx"
```
6. **Take note of the ```instance_ip```**

## Logging into the server
The stage is now set! The last thing to do is test and see if everything is working.
1. **The first option for testing is to launch Minecraft in the version that your server is set for (if you used the provided ```setup-minecraft.sh``` script your version is ```1.20.1```). Then click multiplayer and add server. Name it whatever you please and input the ```instance_ip``` from the previous step as the IP address and connect!**
2. **The second option for testing is to use the nmap command. This option only requires you to have the namp service downloaded. Run the following command to test ```nmap -sV -Pn -p T:25565 <instance_public_ip>```**

# Explanation

This repo uses a combination of terraform and bash scripts to create and deploy the Minecraft server. Terraform works to create and configure the EC2 instance and a bash script is used to download everything you need for the server itself along with creating the proper keys to interact with the instance. 

## Terraform
Three terraform scripts are used to create/configure the instance and execute the necessary bash scripts. ```main.tf``` is the meat and potatoes of it. This script contains some basic things like the configuration of the instance and security groups which can be seen here
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
```
```
resource "aws_security_group" "minecraft" {
  name        = "Minecraft_Security_Group1"
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
The most interesting part of this code is the remote exec section. This is used to grab the ```setup-minecraft.sh``` file and copy it into the instance. It works by ssh into the instance, copying over the file, giving sufficient perm, solving any end-line character issues between Windows and Linux and finally executing the script. This is what downloads all the Minecraft-specific files that are responsible for the hosting of the server. That code can be seen here
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
      "sudo yum install -y dos2unix",
      "until command -v dos2unix >/dev/null 2>&1; do sleep 1; done",
      "dos2unix /home/ec2-user/setup-minecraft.sh",
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
```
The other two terraform files (```output.tf``` and ```variables.tf```) are much less interesting. The ```output.tf``` is simply responsible for printing out the IP address of your instance. That can be seen here
```
output "instance_ip" {
  value = aws_instance.minecraft_server.public_ip
}
```
The ```variables.tf``` file is responsible for keeping track of variables for your public and private keys. This script works closely with our bash scripts. It can be seen here
```
variable "key_name" {
  description = "SSH key pair name for EC2 instance"
  type        = string
  default     = "test"
}

variable "private_key_path" {
  description = "Path to the private key file"
  type        = string
  default     = "C:/Users/nicho/onedrive/desktop/programing/cs 312/minecraft/test.pem"
}
```


## Bash
The bash scripts are responsible for our key generation along with calling the terraform scripts. The ```setup-minecraft.sh``` file that configures all the files necessary for the server to run is also in bash. Starting with the only script that the user will interact with we have ```deploy.sh```. This file calls the ```updateVariables.sh``` script and then CD into the terraform dir before calling the terraform scripts to set up the instance. That can be seen here 
```
#!/bin/bash

# Call updateTerraform.sh to generate key and update variables.tf
./scripts/updateVariables.sh

# Check if the previous script ran successfully
if [ $? -eq 0 ]; then
  echo "Successfully updated variables.tf"

  # Change directory to the terraform configuration directory
  cd ./terraform || exit

  # Run Terraform commands in PowerShell
  powershell.exe -Command "
    terraform init;
    terraform apply -auto-approve;
  "
else
  echo "Failed to update variables.tf. Exiting."
  exit 1
fi
```
The ```updateVariables.sh``` script calls the ```createKey.sh``` script and than copies the generated key name/path into the ```variables.tf``` file for instance configuration. That can be seen here
```
#!/bin/bash

# Call createKey.sh
source ./scripts/createKey.sh

# Check if the key was created successfully
if [ $? -eq 0 ]; then
  # Update variables.tf with the new key name and key file path
  cat > terraform/variables.tf <<EOL
variable "key_name" {
  description = "SSH key pair name for EC2 instance"
  type        = string
  default     = "${KEY_NAME}"
}

variable "private_key_path" {
  description = "Path to the private key file"
  type        = string
  default     = "${KEY_FILE}"
}
EOL

  echo "variables.tf updated with new key name and key file path"
else
  echo "Failed to create key pair. variables.tf not updated."
fi
# End script
```

The ```createKey.sh``` script creates a new AWS key pair. It downloads and changes the permissions of your public key along with storing the path to forward to the ```updateVariables.sh``` script. That can be seen here
```
#!/bin/bash

# Variables
KEY_NAME="test" # Replace with your desired key name
KEY_FILE="${KEY_NAME}.pem"

# Generate the key pair
aws ec2 create-key-pair --key-name "$KEY_NAME" --query 'KeyMaterial' --output text > "$KEY_FILE"

# Check if the key pair was created successfully
if [ $? -eq 0 ]; then
  echo "Key pair $KEY_NAME created and saved to $KEY_FILE"

  # Change permissions of the key file
  chmod 400 "$KEY_FILE"
  echo "Permissions for $KEY_FILE set to 400"

  # Export the key name and key file as environment variables
  export KEY_NAME="$KEY_NAME"
  export KEY_FILE="$(pwd)/$KEY_FILE"

  if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
    KEY_FILE=$(wslpath -m "$KEY_FILE")
  fi
  
else
  echo "Failed to create key pair"
  exit 1
fi
# End script
```

Finally, we have the ```setup-minecraft.sh```script. This is what is used to download all files required for running a Minecraft server in your EC2 instance. This script was taken from an [AWS blog post ](https://aws.amazon.com/ko/blogs/gametech/setting-up-a-minecraft-java-server-on-amazon-ec2/). The file I provided includes an example link to a server jar file for Minecraft version ```1.20.1```. If you would like to change the version of Minecraft that your server runs all you need to do is find a link to that verion's jar file. They can be found [here](https://www.minecraft.net/en-us/download/server). The script can be seen here
```
#!/bin/bash

# *** INSERT SERVER DOWNLOAD URL BELOW ***
# Do not add any spaces between your link and the "=", otherwise it won't work. EG: MINECRAFTSERVERURL=https://urlexample
MINECRAFTSERVERURL='https://piston-data.mojang.com/v1/objects/84194a2f286ef7c14ed7ce0090dba59902951553/server.jar'

# Download Java
sudo yum install -y java-17-amazon-corretto-headless
# Install MC Java server in a directory we create
adduser minecraft
mkdir /opt/minecraft/
mkdir /opt/minecraft/server/
cd /opt/minecraft/server

# Download server jar file from Minecraft official website
wget $MINECRAFTSERVERURL

# Generate Minecraft server files and create script
chown -R minecraft:minecraft /opt/minecraft/
java -Xmx1300M -Xms1300M -jar server.jar nogui
sleep 40
sed -i 's/false/true/p' eula.txt
touch start
printf '#!/bin/bash\njava -Xmx1300M -Xms1300M -jar server.jar nogui\n' >> start
chmod +x start
sleep 1
touch stop
printf '#!/bin/bash\nkill -9 $(ps -ef | pgrep -f "java")' >> stop
chmod +x stop
sleep 1

# Create SystemD Script to run Minecraft server jar on reboot
cd /etc/systemd/system/
touch minecraft.service
printf '[Unit]\nDescription=Minecraft Server on start up\nWants=network-online.target\n[Service]\nUser=minecraft\nWorkingDirectory=/opt/minecraft/server\nExecStart=/opt/minecraft/server/start\nStandardInput=null\n[Install]\nWantedBy=multi-user.target' >> minecraft.service
sudo systemctl daemon-reload
sudo systemctl enable minecraft.service
sudo systemctl start minecraft.service

# End script
```

# Sources
1. [AWS blog post for setup-minecraft script](https://aws.amazon.com/ko/blogs/gametech/setting-up-a-minecraft-java-server-on-amazon-ec2/)
2. [AWS docs for creating key pairs with bash](https://docs.aws.amazon.com/cli/v1/userguide/cli-services-ec2-keypairs.html)
3. [Terraform with AWS blog](https://spacelift.io/blog/terraform-ec2-instance)











