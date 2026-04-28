# 1. Consulta: Busca a imagem oficial e atualizada do Ubuntu 22.04
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
  owners = ["099720109477"] # ID da Canonical, criadora do Ubuntu
}

# 2. O Servidor (EC2)
resource "aws_instance" "spring_boot_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro" # Free Tier
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  # Conectando com a rede pública
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y docker.io
              systemctl start docker
              systemctl enable docker

              export DB_HOST=${aws_db_instance.postgres.address}
              export DB_NAME=userdb
              export DB_USERNAME=lucas

              docker run -d \
                -p 8080:8080 \
                --name api-user-devops \
                -e DB_HOST=$DB_HOST \
                -e DB_NAME=$DB_NAME \
                -e DB_USERNAME=$DB_USERNAME \
                --restart always \
                lucasbschuck/user-devops:latest
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