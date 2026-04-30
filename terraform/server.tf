data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

# 2. O Servidor (EC2)
resource "aws_instance" "spring_boot_server" {
  ami                         = data.aws_ami.ubuntu.id
  key_name                    = "LucasNot"
  instance_type               = "t3.micro"
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true

  # Conectando com a rede pública
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

              apt-get update -y
              apt-get install -y docker.io
              systemctl start docker
              systemctl enable docker

              # 1. Sobe a API
              docker pull lucasbschuck/user-devops-api:latest

              docker run -d \
                -p 8080:8080 \
                --name api-user-devops \
                --restart always \
                lucasbschuck/user-devops-api:latest

              # 2. Sobe o Watchtower
              docker run -d \
                --name watchtower \
                -v /var/run/docker.sock:/var/run/docker.sock \
                containrrr/watchtower \
                --interval 30 \
                --cleanup \
                api-user-devops
              EOF

  tags = {
    Name = "spring-boot-api-server"
  }
}