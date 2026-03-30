# 1. Look up the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

# 2. Create the EC2 Instance (The "Patient")
resource "aws_instance" "auto_healer_server" {
  count         = 5
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"

  # Networking
  subnet_id              = aws_subnet.auto-healer-public.id
  vpc_security_group_ids = [aws_security_group.healer_sg_1.id]

  # The Identity Badge "Handshake"
  iam_instance_profile = aws_iam_instance_profile.auto_healer_instance_profile.name

  # User Data: This script runs once at birth to install our testing tool
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y stress-ng
              EOF

  tags = {
    Name        = "Auto-Healer-Patient-${count.index}"
    Project     = "Auto-Healing-Infrastructure-Project"
    Environment = "Dev"
  }
}