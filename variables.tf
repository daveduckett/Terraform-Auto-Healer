variable "vpc_cidr_healer" {
  description = "The CIDR block for the Auto Healer VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_healer" {
  description = "The CIDR block for the public subnet in auto-healer vpc"
  type        = string
  default     = "10.0.1.0/24"
}