variable "key_name" {
  description = "SSH key pair name for EC2 instance"
  type        = string
  default     = "Course Project"
}

variable "private_key_path" {
  description = "Path to the private key file"
  type        = string
  default     = "C:/Users/nicho/OneDrive/Desktop/Programing/CS 312/minecraft/Course-Project.pem"
}