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
