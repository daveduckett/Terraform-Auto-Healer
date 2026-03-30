resource "aws_security_group" "healer_sg_1" {
  name        = "auto-healer-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.auto-healer-vpc.id

  # Inbound Rules (Ingress)
  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # The whole world
  }

  # Outbound Rules (Egress)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # "-1" means ALL protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "healer-sg"
  }
}